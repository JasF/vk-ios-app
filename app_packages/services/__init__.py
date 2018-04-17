from .wallservice import WallServiceHandlerProtocol
from .chatlistservice import ChatListService
from objcbridge import BridgeBase, Subscriber
from vk import LongPoll
from .messagesservice import MessagesService

Subscriber().setClassHandler(WallServiceHandlerProtocol())

MessagesService().setLongPoll( LongPoll() )
