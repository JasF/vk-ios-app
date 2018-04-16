from .menuscreen import MenuHandlerProtocol
from .newsscreen import NewsHandlerProtocol
from .dialogsscreen import DialogsHandlerProtocol
from .authorizationscreen import AuthorizationHandlerProtocol
from .dialogscreen import DialogHandlerProtocol
from objcbridge import BridgeBase, Subscriber
from vk import LongPoll
from viewmodels.dialogscreenviewmodel import DialogScreenViewModel
from services.messagesservice import MessagesService

Subscriber().setClassHandler(MenuHandlerProtocol())
Subscriber().setClassHandler(NewsHandlerProtocol())
Subscriber().setClassHandler(DialogsHandlerProtocol())
Subscriber().setClassHandler(AuthorizationHandlerProtocol())
Subscriber().setClassHandler(DialogHandlerProtocol( DialogScreenViewModel(MessagesService()) ))
