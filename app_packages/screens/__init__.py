from .authorizationscreen import AuthorizationHandlerProtocol
from objcbridge import BridgeBase, Subscriber

Subscriber().setClassHandler(AuthorizationHandlerProtocol())
