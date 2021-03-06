import vk
import threading
import requests
from functools import partial
import functools
from enum import Enum
from systemevents import SystemEvents
import inspect, json
import traceback
from caches.messagesdatabase import MessagesDatabase

class Event(Enum): # https://vk.com/dev/using_longpoll?f=3.%20Структура%20событий
    MESSAGE_SET_FLAGS = 1
    MESSAGE_ADD_FLAGS = 2
    MESSAGE_CLEAR_FLAGS = 3
    MESSAGE_ADD = 4
    MESSAGE_EDIT = 5
    MESSAGES_IN_READED = 6
    MESSAGES_OUT_READED = 7
    USER_ONLINE = 8
    USER_OFFLINE = 9
    DIALOG_CLEAR_FLAGS = 10
    DIALOG_SET_FLAGS = 11
    DIALOG_ADD_FLAGS = 12
    DIALOG_MESSAGES_REMOVE = 13
    DIALOG_MESSAGES_RESTORE = 14
    CHAT_PARAMETER_CHANGE = 51
    USER_DIALOG_TYPING = 61 # 5 seconds active
    USER_CHAT_TYPING = 62
    USER_CALL = 70

handlers = {}
lp_version=3
need_pts=1

FLAG_ATTACHMENTS = 2
FLAG_PTS = 32
FLAG_RANDOM_D = 128

class AddMessageProtocol(object):
    def handleMessageAdd(self, messageId, flags, peerId, timestamp, text):
        pass
    def handleMessageEdit(self, messageId, flags, peerId, timestamp, text):
        pass
    def handleMessageClearFlags(self, messageId, flags):
        pass
    def handleTyping(self, userId, flags):
        pass

class LongPoll:
    def __new__(cls):
        if not hasattr(cls, 'instance') or not cls.instance:
            cls.instance = super().__new__(cls)
            cls.addMessageDelegates = []
            cls.longPollThread = None
            cls.ts = 0
            cls.pts = 0
            SystemEvents().addHandler(cls.instance)
        return cls.instance

    def connectToLongPollServer(self, key, server, ts, pts, currentThread):
        requests_session = requests.Session()
        
        while True:
            try:
                timeout = 25
                url = 'https://' + server + '?act=a_check&key=' + str(key) + '&ts=' + str(ts) + '&wait=' + str(timeout) + '&mode=' + str(FLAG_ATTACHMENTS+FLAG_PTS+FLAG_RANDOM_D) + '&version=2'
                #print('longpoll request: ' + str(url))
                response = requests_session.get(url, timeout=timeout+5)
                jsonDict = response.json()
                #print('longpoll response: ' + json.dumps(jsonDict, indent=4))
                if self.longPollThread != currentThread:
                    print('LongPollThread is changed. Current session is invalid! Returning...')
                    return
                if not isinstance(jsonDict, dict):
                    print('unknown output from longPollServer. possible connection lost. repeating...')
                    continue
                failedCode = jsonDict.get('failed')
                if isinstance(failedCode, int):
                    print('longpoll failed with: ' + str(failedCode))
                    if len(vk.token()) == 0:
                        print('token not found. stopping longpoll')
                        return
                    #print('needs restart long poll. stopping current longpoll and creating new loop')
                    self.connect_after_error()
                    return
                
                newTs = jsonDict.get('ts')
                pts = jsonDict.get('pts')
                if not isinstance(pts, int):
                    pts = jsonDict.get('new_pts')
                #print('NEXT LINE FOR DELETE')
                #self.performLongPollHistory()
                #print('PREVIOUS LINE FOR DELETE')
                if isinstance(pts, int):
                    self.pts = pts
                updates = jsonDict.get('updates')
                if newTs and newTs > 0:
                    ts = newTs
                self.ts = ts
                if isinstance(updates, list):
                    threading.Thread(target=partial(parseUpdates, updates)).start()
            except Exception as e:
                print('longpoll exception: ' + str(e))
                pass

    def performLongPollHistory(self):
        try:
            api = vk.api()
            response = api.messages.getLongPollHistory(ts=self.ts, pts=self.pts)
            history = response.get('history')
            messages = response.get('messages')
            #print('longpoll response is: ' + str(response))
            if isinstance(messages, dict):
                l = messages.get('items')
                if isinstance(l, list):
                    cache = MessagesDatabase()
                    cache.update(l)
                    cache.close()
            if isinstance(history, list):
                threading.Thread(target=partial(parseUpdates, history)).start()
        except Exception as e:
            print('performLongPollHistory exception: ' + str(e))
        pass
    
    def doConnect(self):
        currentThread = self.longPollThread
        api = vk.api()
        response = api.messages.getLongPollServer(need_pts=need_pts, lp_version=lp_version)
        self.connectToLongPollServer(response['key'], response['server'], response['ts'], response['pts'], currentThread)

    def connect_after_error(self):
        if self.pts > 0 and self.ts > 0:
            print('connect_after_error with longPollHistory')
            self.performLongPollHistory()
        else:
            print('connect_after_error without pts: ' + str(self.pts) + ' or ts: ' + str(self.ts))
        self.connect()
    
    def connect(self):
        self.ts = 0
        self.pts = 0
        def performConnect():
            self.doConnect()
        self.longPollThread = threading.Thread(target=performConnect)
        self.longPollThread.start()

    def addAddMessageDelegate(self, delegate):
        self.addMessageDelegates.append(delegate)

    # SystemEvents
    def applicationDidEnterBackground(self):
        print('longpoll applicationDidEnterBackground')
        pass
    
    def applicationWillEnterForeground(self):
        if isinstance(self.longPollThread, threading.Thread):
            if self.longPollThread.isAlive():
                print('longpoll thread is alive')
                return
        self.connect()
        pass

_lp = LongPoll()

def parseUpdates(updates):
    #print('updates: ' + json.dumps(updates, indent=4))
    for eventDescription in updates:
        try:
            parseEvent(eventDescription)
        except Exception as e:
            print('parse event exception: ' + str(e) + '; event: ' + str(eventDescription))
            print(traceback.format_exc())

def parseEvent(eventDescription):
    if len(eventDescription) == 0:
        return
    id = eventDescription.pop(0)
    try:
        event = Event(id)
        handler = handlers.get(event)
        if handler:
            handler(eventDescription)
        else:
            print('handler missing')
    except:
        print('unknown longpoll id: ' + str(id))

def parseMessageSetFlags(eventDescription):
    pass

def parseMessageAddFlags(eventDescription):
    if len(eventDescription) < 2:
        print('parseMessageAddFlags too short')
        return
    messageId = eventDescription[0]
    flags = eventDescription[1]
    for d in _lp.addMessageDelegates:
        d.handleMessageAddFlags(messageId, flags)
    pass

def parseMessageClearFlags(eventDescription):
    if len(eventDescription) < 2:
        print('parseMessageClearFlags too short')
        return
    messageId = eventDescription[0]
    flags = eventDescription[1]
    for d in _lp.addMessageDelegates:
        d.handleMessageClearFlags(messageId, flags)

def parseMessageAdd(eventDescription):
    if len(eventDescription) < 3:
        print('parseMessageAdd too short')
        return
    messageId = eventDescription[0]
    flags = eventDescription[1]
    peerId = eventDescription[2]

    timestamp = 0
    text = ""
    extra = {}
    random_id = 0

    if len(eventDescription) >= 7:
        timestamp = eventDescription[3]
        text = eventDescription[4]
        extra = eventDescription[5]
        random_id = eventDescription[6]

    print('msg add desc: ' + json.dumps(eventDescription, indent=4) + ' and delegates: ' + str(_lp.addMessageDelegates))
    
    for d in _lp.addMessageDelegates:
        d.handleMessageAdd(messageId, flags, peerId, timestamp, text, random_id, extra)

def parseMessageEdit(eventDescription):
    if len(eventDescription) < 7:
        print('parseMessageAdd too short')
        return
    messageId = eventDescription[0]
    flags = eventDescription[1]
    peerId = eventDescription[2]
    timestamp = eventDescription[3]
    text = eventDescription[4]
    extra = eventDescription[5]
    random_id = eventDescription[6]

    print('msg EDIT desc: ' + json.dumps(eventDescription, indent=4))
    for d in _lp.addMessageDelegates:
        d.handleMessageEdit(messageId, flags, peerId, timestamp, text, random_id, extra)

def parseMessageInReaded(eventDescription):
    if len(eventDescription) < 2:
        print('parseMessageInReaded too short')
        return
    peerId = eventDescription[0]
    localId = eventDescription[1]
    for d in _lp.addMessageDelegates:
        d.handleMessagesInReaded(peerId, localId)

def parseMessageOutReaded(eventDescription):
    if len(eventDescription) < 2:
        print('parseMessageOutReaded too short')
        return
    peerId = eventDescription[0]
    localId = eventDescription[1]
    for d in _lp.addMessageDelegates:
        d.handleMessagesOutReaded(peerId, localId)

def parseUserOnline(eventDescription):
    pass

def parseUserOffline(eventDescription):
    pass

def parseClearFlags(eventDescription):
    pass

def parseSetFlags(eventDescription):
    pass

def parseAddFlags(eventDescription):
    pass

def parseMessagesRemove(eventDescription):
    pass

def parseMessagesRestore(eventDescription):
    pass

def parseParameterChange(eventDescription):
    pass

def parseDialogTyping(eventDescription):
    userId = eventDescription[0]
    flags = eventDescription[1]
    for d in _lp.addMessageDelegates:
        d.handleTyping(userId, flags)
    pass

def parseChatTyping(eventDescription):
    pass

def parseCall(eventDescription):
    pass

handlers = {
Event.MESSAGE_SET_FLAGS:parseMessageSetFlags,
Event.MESSAGE_ADD_FLAGS:parseMessageAddFlags,
Event.MESSAGE_CLEAR_FLAGS:parseMessageClearFlags,
Event.MESSAGE_ADD:parseMessageAdd,
Event.MESSAGE_EDIT:parseMessageEdit,
Event.MESSAGES_IN_READED:parseMessageInReaded,
Event.MESSAGES_OUT_READED:parseMessageOutReaded,
Event.USER_ONLINE:parseUserOnline,
Event.USER_OFFLINE:parseUserOffline,
Event.DIALOG_CLEAR_FLAGS:parseClearFlags,
Event.DIALOG_SET_FLAGS:parseSetFlags,
Event.DIALOG_ADD_FLAGS:parseAddFlags,
Event.DIALOG_MESSAGES_REMOVE:parseMessagesRemove,
Event.DIALOG_MESSAGES_RESTORE:parseMessagesRestore,
Event.CHAT_PARAMETER_CHANGE:parseParameterChange,
Event.USER_DIALOG_TYPING:parseDialogTyping,
Event.USER_CHAT_TYPING:parseChatTyping,
Event.USER_CALL:parseCall
}
