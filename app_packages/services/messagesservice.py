from vk import LongPoll
import vk, json
from vk.longpoll import AddMessageProtocol
from caches.messagesdatabase import MessagesDatabase
from enum import Flag, auto
import threading

class MessageFlags(Flag):
    UNREAD = auto()
    OUTBOX = auto()
    REPLIED = auto()
    IMPORTANT = auto()
    CHAT = auto()
    FRIENDS = auto()
    SPAM = auto()
    DELETED = auto()
    FIXED = auto()
    MEDIA = auto()
    HIDDEN = 65536
    DELETED_FOR_ALL = 131072

class NewMessageProtocol():
    def handleIncomingMessage(self, messageId, flags, peerId, timestamp, text):
        pass
    def handleMessageFlagsChanged(self, message):
        pass
    def handleMessagesInReaded(self, peerId, messageId):
        pass
    def handleMessagesOutReaded(self, peerId, messageId):
        pass
    def handleTypingInDialog(self, userId, flags):
        pass
    def handleMessageDeleted(self, messageId):
        pass

class MessagesService(AddMessageProtocol):
    def __new__(cls):
        if not hasattr(cls, 'instance') or not cls.instance:
            cls.instance = super().__new__(cls)
            cls.newMessageSubscribers = []
        return cls.instance

    def addNewMessageSubscriber(self, subscriber):
        self.newMessageSubscribers.append(subscriber)
        #print('new message subscriber is: ' + str(subscriber))
        pass
    
    def removeNewMessageSubscriber(self, subscriber):
        self.newMessageSubscribers.remove(subscriber)

    def setLongPoll(self, longPoll):
        self.longPoll = longPoll
        self.longPoll.addAddMessageDelegate(self)
    
    def messageDictionary(self, messageId, isOut, userId, fromId, timestamp, text, read_state, randomId):
        dict = {'id':messageId, 'user_id': userId, 'from_id': fromId, 'date': timestamp, 'read_state': read_state, 'out': isOut, 'body': text, 'random_id': randomId}
        return dict

    def saveMessageToCache(self, messageId, isOut, userId, fromId, timestamp, text, read_state, randomId):
        dict = self.messageDictionary(messageId, isOut, userId, fromId, timestamp, text, read_state, randomId)
        #print('updating dict: ' + str(dict))
        messages = MessagesDatabase()
        messages.update([dict])
        messages.close()
    
    def messageWithId(sekf, messageId):
        database = MessagesDatabase()
        result = database.messageWithId(messageId)
        database.close()
        return result

    # AddMessageProtocol
    def handleMessageAdd(self, messageId, flags, peerId, timestamp, text, randomId):
        isOut = 1 if MessageFlags(flags) & MessageFlags.OUTBOX else 0
        read_state = 0 if MessageFlags(flags) & MessageFlags.UNREAD else 1
        fromId = vk.userId() if isOut == True else peerId
        #print('handle incoming message: peerId: ' + str(peerId) + '; fromId: ' + str(fromId) + '; randomId: ' + str(randomId))
        try:
            cache = MessagesDatabase()
            msg = cache.messageWithId(randomId)
            cache.close()
            if isinstance(msg.get('id'), int):
                #print('message exists!')
                return
        except:
            pass
        msg = self.messageDictionary(messageId, isOut, peerId, fromId, timestamp, text, read_state, randomId)
        for d in self.newMessageSubscribers:
            d.handleIncomingMessage(msg)
        self.saveMessageToCache(messageId, isOut, peerId, fromId, timestamp, text, read_state, randomId)

    def handleMessageEdit(self, messageId, flags, peerId, timestamp, text, randomId):
        isOut = 1 if MessageFlags(flags) & MessageFlags.OUTBOX else 0
        read_state = 0 if MessageFlags(flags) & MessageFlags.UNREAD else 1
        fromId = vk.userId() if isOut == True else peerId
        try:
            self.saveMessageToCache(messageId, isOut, peerId, fromId, timestamp, text, read_state, randomId)
            msg = self.messageDictionary(messageId, isOut, peerId, fromId, timestamp, text, read_state, randomId)
            for d in self.newMessageSubscribers:
                d.handleEditMessage(msg)
        except:
            pass

    def markReadedMessagesBefore(self, peerId, localId, out):
        cache = MessagesDatabase()
        l = cache.unreadedMessagesBefore(peerId, localId, out)
        for d in l:
            d['read_state'] = 1
        cache.update(l)
        #print('markReadedMessagesBefore unreaded: ' + json.dumps(l, indent=4) + '; out: ' + str(out) + ('; peer_id: ' if out == False else '; user_id: ') + str(peerId))
        cache.close()
    
    def handleMessagesInReaded(self, peerId, localId):
        try:
            self.markReadedMessagesBefore(peerId, localId, False)
            for d in self.newMessageSubscribers:
                d.handleMessagesInReaded(peerId, localId)
        except Exception as e:
            print('handleMessagesInReaded exception: ' + str(e))
    
    def handleMessagesOutReaded(self, peerId, localId):
        try:
            self.markReadedMessagesBefore(peerId, localId, True)
            for d in self.newMessageSubscribers:
                d.handleMessagesOutReaded(peerId, localId)
        except Exception as e:
            print('handleMessagesOutReaded exception: ' + str(e))

    def handleMessageClearFlags(self, messageId, flags):
        if not MessageFlags(flags) & MessageFlags.UNREAD:
            print('clearing unknown flags: ' + str(MessageFlags(flags)) + ' for msgid: ' + str(messageId))
        
        read_state = 1 if MessageFlags(flags) & MessageFlags.UNREAD else 0
        dict = {'id':messageId, 'read_state': read_state}
        messages = MessagesDatabase()
        messages.update([dict])
        msg = messages.messageWithId(messageId)
        messages.close()
        for d in self.newMessageSubscribers:
            d.handleMessageFlagsChanged(msg)


    def handleMessageAddFlags(self, messageId, flags):
        if MessageFlags(flags) & MessageFlags.DELETED_FOR_ALL:
            try:
                messages = MessagesDatabase()
                messages.remove(messageId)
                messages.close()
                for d in self.newMessageSubscribers:
                    d.handleMessageDeleted(messageId)
            except Exception as e:
                print('delete message exception: ' + str(e))
            return
        print('added unknown flag for message: ' + str(messageId))

    def handleTyping(self, userId, flags):
        print('count of subscr: ' + str(len(self.newMessageSubscribers)))
        for d in self.newMessageSubscribers:
            try:
                def call():
                    d.handleTypingInDialog(userId, flags)
                threading.Thread(target=call).start()
            except Exception as e:
                print('handleTyping exception: ' + str(e))

    def remove(self, id):
        try:
            messages = MessagesDatabase()
            messages.remove(id)
            messages.close()
        except Exception as e:
            print('remove message exception: ' + str(e))

    def changeId(self, oldId, newId):
        try:
            messages = MessagesDatabase()
            messages.changeId(oldId, newId)
            messages.close()
        except Exception as e:
            print('changeId message exception: ' + str(e))

