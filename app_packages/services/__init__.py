from .wallservice import WallServiceHandlerProtocol
from .dialogsservice import DialogsServiceHandlerProtocol

from .pydialogservice import PyDialogService
from objcbridge import BridgeBase, Subscriber
from vk import LongPoll
from .messagesservice import MessagesService

Subscriber().setClassHandler(WallServiceHandlerProtocol())
Subscriber().setClassHandler(DialogsServiceHandlerProtocol())
Subscriber().setClassHandler(PyDialogService())

MessagesService().setLongPoll( LongPoll() )
