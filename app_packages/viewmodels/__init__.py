from objcbridge import BridgeBase, Subscriber
from viewmodels.pydialogscreenviewmodel import PyDialogScreenViewModel
from .pychatlistscreenviewmodel import PyChatListScreenViewModel
from .pywallscreenviewmodel import PyWallScreenViewModel
from .pymenuscreenviewmodel import PyMenuScreenViewModel

from services.messagesservice import MessagesService
from services.chatlistservice import ChatListService
from services.dialogservice import DialogService
from services.wallservice import WallService

Subscriber().setClassAllocatorWithDelegate( PyChatListScreenViewModel, lambda delegateId: PyChatListScreenViewModel(delegateId, MessagesService(), ChatListService()) )
Subscriber().setClassAllocatorWithDelegate( PyDialogScreenViewModel, lambda delegateId: PyDialogScreenViewModel(delegateId, MessagesService(), DialogService()) )
Subscriber().setClassAllocatorWithDelegate( PyDialogScreenViewModel, lambda delegateId: PyDialogScreenViewModel(delegateId, MessagesService(), DialogService()) )
Subscriber().setClassAllocator( PyWallScreenViewModel, lambda: PyWallScreenViewModel(WallService()) )
Subscriber().setClassAllocator( PyMenuScreenViewModel, lambda: PyMenuScreenViewModel() )

