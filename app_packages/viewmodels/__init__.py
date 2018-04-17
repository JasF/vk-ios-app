from objcbridge import BridgeBase, Subscriber
from viewmodels.pydialogscreenviewmodel import PyDialogScreenViewModel
from services.messagesservice import MessagesService

Subscriber().setClassHandler( PyDialogScreenViewModel(MessagesService()) )
