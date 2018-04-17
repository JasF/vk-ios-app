from vk import LongPoll
from vk.longpoll import AddMessageProtocol

class NewMessageProtocol():
    def handleIncomingMessage(self, userId, body):
        pass

class MessagesService(AddMessageProtocol):
    def __new__(cls):
        if not hasattr(cls, 'instance') or not cls.instance:
            cls.instance = super().__new__(cls)
            cls.newMessageSubscribers = []
        return cls.instance

    def addNewMessageSubscriber(self, subscriber):
        self.newMessageSubscribers.append(subscriber)
        print('new message subscriber is: ' + str(subscriber))
        pass
    
    def removeNewMessageSubscriber(self, subscriber):
        self.newMessageSubscribers.remove(subscriber)

    def setLongPoll(self, longPoll):
        self.longPoll = longPoll
        self.longPoll.addAddMessageDelegate(self)

    # AddMessageProtocol
    def handleMessageAdd(self, userId, timestamp, body):
        print('handleMessageAdd: ' + str(body))
        for d in self.newMessageSubscribers:
            try:
                d.handleIncomingMessage(userId, timestamp, body)
            except Exception as e:
                print('notifying add message exception: ' + str(e))
