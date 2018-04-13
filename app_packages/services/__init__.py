from .wallservice import WallServiceHandlerProtocol
from .dialogsservice import DialogsServiceHandlerProtocol
from objcbridge import BridgeBase, Subscriber

Subscriber().setClassHandler(WallServiceHandlerProtocol())
Subscriber().setClassHandler(DialogsServiceHandlerProtocol())
