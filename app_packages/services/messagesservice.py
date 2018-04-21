from vk import LongPoll
import vk
from vk.longpoll import AddMessageProtocol
from caches.messages import MessagesDatabase
from enum import Flag, auto

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
    def handleTypingInDialog(self, userId, flags):
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
    
    def messageDictionary(self, messageId, isOut, userId, fromId, timestamp, text, read_state):
        dict = {'id':messageId, 'user_id': userId, 'from_id': fromId, 'date': timestamp, 'read_state': read_state, 'out': isOut, 'body': text}
        return dict

    def saveMessageToCache(self, messageId, isOut, userId, fromId, timestamp, text, read_state):
        dict = self.messageDictionary(messageId, isOut, userId, fromId, timestamp, text, read_state)
        print('updating dict: ' + str(dict))
        messages = MessagesDatabase()
        messages.update([dict])
        messages.close()
    
    def messageWithId(sekf, messageId):
        database = MessagesDatabase()
        result = database.messageWithId(messageId)
        database.close()
        return result

    # AddMessageProtocol
    def handleMessageAdd(self, messageId, flags, peerId, timestamp, text):
        isOut = 1 if MessageFlags(flags) & MessageFlags.OUTBOX else 0
        read_state = 0 if MessageFlags(flags) & MessageFlags.UNREAD else 1
        fromId = vk.userId() if isOut == True else peerId
        print('handle incoming message: peerId: ' + str(peerId) + '; fromId: ' + str(fromId))
        msg = self.messageDictionary(messageId, isOut, peerId, fromId, timestamp, text, read_state)
        for d in self.newMessageSubscribers:
            d.handleIncomingMessage(msg)
        self.saveMessageToCache(messageId, isOut, peerId, fromId, timestamp, text, read_state)

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

    def handleTyping(self, userId, flags):
        for d in self.newMessageSubscribers:
            d.handleTypingInDialog(userId, flags)
