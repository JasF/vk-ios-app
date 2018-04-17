import vk
import threading
import requests
from functools import partial
import functools
from enum import Enum
import inspect



class Event(Enum):
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

class AddMessageProtocol(object):
    def handleMessageAdd(self, userId, timestamp, body):
        pass
'''
class LongPollProtocol():
    def handleMessageSetFlags(self):
        pass
    def handleMessageAddFlags(self):
        pass
    def handleMessageClearFlags(self):
        pass
    def handleMessageAdd(self):
        pass
    def handleMessageEdit(self):
        pass
    def handleMessageInReaded(self):
        pass
    def handleMessageOutReaded(self):
        pass
    def handleUserOnline(self):
        pass
    def handleUserOffline(self):
        pass
    def handleClearFlags(self):
        pass
    def handleSetFlags(self):
        pass
    def handleAddFlags(self):
        pass
    def handleMessagesRemove(self):
        pass
    def handleMessagesRestore(self):
        pass
    def handleParameterChange(self):
        pass
    def handleDialogTyping(self):
        pass
    def handleChatTyping(self):
        pass
    def handleCall(self):
        pass
'''

class LongPoll:
    def __new__(cls):
        if not hasattr(cls, 'instance') or not cls.instance:
            cls.instance = super().__new__(cls)
            cls.addMessageDelegates = []
        return cls.instance

    def connectToLongPollServer(self, key, server, ts, pts):
        requests_session = requests.Session()
        
        while True:
            url = 'https://' + server + '?act=a_check&key=' + str(key) + '&ts=' + str(ts) + '&wait=25&mode=2&version=2'
            response = requests_session.get(url)
            json = response.json()
            print('LongPoll response: ' + str(json))
            newTs = json.get('ts')
            updates = json.get('updates')
            if newTs and newTs > 0:
                ts = newTs
            if isinstance(updates, list):
                threading.Thread(target=partial(parseUpdates, updates)).start()

    def doConnect(self):
        api = vk.api()
        response = api.messages.getLongPollServer(need_pts=need_pts, lp_version=lp_version)
        self.connectToLongPollServer(response['key'], response['server'], response['ts'], response['pts'])

    def connect(self):
        def performConnect():
            self.doConnect()
        threading.Thread(target=performConnect).start()

    def addAddMessageDelegate(self, delegate):
        self.addMessageDelegates.append(delegate)

_lp = LongPoll()

def parseUpdates(updates):
    #print('updates: ' + str(updates))
    for eventDescription in updates:
        try:
            parseEvent(eventDescription)
        except Exception as e:
            print('parse event exception: ' + str(e) + '; event: ' + str(eventDescription))

def parseEvent(eventDescription):
    if len(eventDescription) == 0:
        return
    id = eventDescription.pop(0)
    event = Event(id)
    print('Incoming event: ' + str(event))
    handler = handlers.get(event)
    if handler:
        handler(eventDescription)
    else:
        print('handler missing')

def parseMessageSetFlags(eventDescription):
    pass

def parseMessageAddFlags(eventDescription):
    pass

def parseMessageClearFlags(eventDescription):
    pass

def parseMessageAdd(eventDescription):
    if len(eventDescription) < 5:
        print('parseMessageAdd too short')
        return
    messageId = eventDescription[0]
    flags = eventDescription[1]
    peerId = eventDescription[2]
    timestamp = eventDescription[3]
    text = eventDescription[4]
    
    for d in _lp.addMessageDelegates:
        d.handleMessageAdd(peerId, timestamp, text)

def parseMessageEdit(eventDescription):
    pass

def parseMessageInReaded(eventDescription):
    pass

def parseMessageOutReaded(eventDescription):
    pass

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
