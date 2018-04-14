from .wallservice import WallServiceHandlerProtocol
from .dialogsservice import DialogsServiceHandlerProtocol
from .dialogservice import DialogServiceHandlerProtocol
from objcbridge import BridgeBase, Subscriber

Subscriber().setClassHandler(WallServiceHandlerProtocol())
Subscriber().setClassHandler(DialogsServiceHandlerProtocol())
Subscriber().setClassHandler(DialogServiceHandlerProtocol())
