from .wallservice import WallServiceHandlerProtocol
from .chatlistservice import ChatListService
from .pydialogservice import PyDialogService
from objcbridge import BridgeBase, Subscriber
from vk import LongPoll
from .messagesservice import MessagesService

Subscriber().setClassHandler(WallServiceHandlerProtocol())
Subscriber().setClassHandler(ChatListService())
Subscriber().setClassHandler(PyDialogService())

MessagesService().setLongPoll( LongPoll() )
