from .menuscreen import MenuHandlerProtocol
from .newsscreen import NewsHandlerProtocol
from .dialogsscreen import DialogsHandlerProtocol
from .authorizationscreen import AuthorizationHandlerProtocol
from .dialogscreen import DialogHandlerProtocol
from objcbridge import BridgeBase, Subscriber

Subscriber().setClassHandler(MenuHandlerProtocol())
Subscriber().setClassHandler(NewsHandlerProtocol())
Subscriber().setClassHandler(DialogsHandlerProtocol())
Subscriber().setClassHandler(AuthorizationHandlerProtocol())
Subscriber().setClassHandler(DialogHandlerProtocol())
