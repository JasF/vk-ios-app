from objcbridge import BridgeBase, Subscriber
from viewmodels.pydialogscreenviewmodel import PyDialogScreenViewModel
from .pychatlistscreenviewmodel import PyChatListScreenViewModel
from services.messagesservice import MessagesService
from services.chatlistservice import ChatListService

Subscriber().setClassHandler( PyDialogScreenViewModel(MessagesService()) )
Subscriber().setClassAllocator( PyChatListScreenViewModel, lambda: PyChatListScreenViewModel(MessagesService(), ChatListService()) )
