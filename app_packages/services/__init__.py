from .wallservice import WallServiceHandlerProtocol
from .dialogsservice import DialogsServiceHandlerProtocol
from .dialogservice import DialogServiceHandlerProtocol
from objcbridge import BridgeBase, Subscriber
from vk import LongPoll
from .messagesservice import MessagesService

Subscriber().setClassHandler(WallServiceHandlerProtocol())
Subscriber().setClassHandler(DialogsServiceHandlerProtocol())
Subscriber().setClassHandler(DialogServiceHandlerProtocol())

MessagesService().setLongPoll( LongPoll() )
