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

    def saveMessageToCache(self, messageId, isOut, userId, fromId, timestamp, text):
        dict = {'id':messageId, 'user_id': userId, 'from_id': fromId, 'date': timestamp, 'read_state': 0, 'out': isOut, 'body': text}
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
        fromId = vk.userId() if isOut == True else peerId
        print('handle incoming message: peerId: ' + str(peerId) + '; fromId: ' + str(fromId))
        
        for d in self.newMessageSubscribers:
            try:
                d.handleIncomingMessage(messageId, flags, peerId, timestamp, text)
            except Exception as e:
                print('notifying add message exception: ' + str(e))

        self.saveMessageToCache(messageId, isOut, peerId, fromId, timestamp, text)
