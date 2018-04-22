from objcbridge import BridgeBase, Subscriber
from viewmodels.pydialogscreenviewmodel import PyDialogScreenViewModel
from .pychatlistviewmodel import PyChatListViewModel
from .pywallscreenviewmodel import PyWallScreenViewModel
from .pymenuscreenviewmodel import PyMenuScreenViewModel
from .pyfriendsviewmodel import PyFriendsViewModel

from services.messagesservice import MessagesService
from services.chatlistservice import ChatListService
from services.dialogservice import DialogService
from services.wallservice import WallService
from services.friendsservice import FriendsService

Subscriber().setClassAllocatorWithDelegate( PyChatListViewModel, lambda delegateId: PyChatListViewModel(delegateId, MessagesService(), ChatListService()) )
Subscriber().setClassAllocatorWithDelegate( PyDialogScreenViewModel, lambda delegateId, parameters: PyDialogScreenViewModel(delegateId, parameters, MessagesService(), DialogService()) )
Subscriber().setClassAllocator( PyWallScreenViewModel, lambda: PyWallScreenViewModel(WallService()) )
Subscriber().setClassAllocator( PyMenuScreenViewModel, lambda: PyMenuScreenViewModel() )
Subscriber().setClassAllocator( PyFriendsViewModel, lambda: PyFriendsViewModel(FriendsService()) )


