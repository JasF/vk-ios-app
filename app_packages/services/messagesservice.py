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
        print('new message subscriber is: ' + str(subscriber))
        self.newMessageSubscribers.append(subscriber)
        pass

    def setLongPoll(self, longPoll):
        self.longPoll = longPoll
        self.longPoll.addAddMessageDelegate(self)

    # AddMessageProtocol
    def handleMessageAdd(self, userId, timestamp, body):
        for d in self.newMessageSubscribers:
            d.handleIncomingMessage(userId, timestamp, body)
