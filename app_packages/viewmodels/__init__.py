from objcbridge import BridgeBase, Subscriber
from viewmodels.pydialogscreenviewmodel import PyDialogScreenViewModel
from .pychatlistscreenviewmodel import PyChatListScreenViewModel
from services.messagesservice import MessagesService
from services.chatlistservice import ChatListService
from services.dialogservice import DialogService

Subscriber().setClassAllocator( PyChatListScreenViewModel, lambda: PyChatListScreenViewModel(MessagesService(), ChatListService()) )
Subscriber().setClassAllocator( PyDialogScreenViewModel, lambda: PyDialogScreenViewModel(MessagesService(), DialogService()) )
