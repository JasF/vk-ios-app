from .wallservice import WallServiceHandlerProtocol
from .dialogsservice import DialogsServiceHandlerProtocol
from objcbridge import BridgeBase, Subscriber

def initializeServices():
    Subscriber().setClassHandler(WallServiceHandlerProtocol())
    Subscriber().setClassHandler(DialogsServiceHandlerProtocol())
