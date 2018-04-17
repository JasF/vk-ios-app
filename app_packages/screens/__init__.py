from .menuscreen import MenuHandlerProtocol
from .authorizationscreen import AuthorizationHandlerProtocol
from objcbridge import BridgeBase, Subscriber

Subscriber().setClassHandler(MenuHandlerProtocol())
Subscriber().setClassHandler(AuthorizationHandlerProtocol())
