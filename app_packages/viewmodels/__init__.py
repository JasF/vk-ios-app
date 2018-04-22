from objcbridge import BridgeBase, Subscriber
from viewmodels.pydialogscreenviewmodel import PyDialogScreenViewModel
from .pychatlistviewmodel import PyChatListViewModel
from .pywallviewmodel import PyWallViewModel
from .pymenuviewmodel import PyMenuViewModel
from .pyfriendsviewmodel import PyFriendsViewModel

from services.messagesservice import MessagesService
from services.chatlistservice import ChatListService
from services.dialogservice import DialogService
from services.wallservice import WallService
from services.friendsservice import FriendsService

Subscriber().setClassAllocatorWithDelegate( PyChatListViewModel, lambda delegateId: PyChatListViewModel(delegateId, MessagesService(), ChatListService()) )
Subscriber().setClassAllocatorWithDelegate( PyDialogScreenViewModel, lambda delegateId, parameters: PyDialogScreenViewModel(delegateId, parameters, MessagesService(), DialogService()) )
Subscriber().setClassAllocator( PyWallViewModel, lambda: PyWallViewModel(WallService()) )
Subscriber().setClassAllocator( PyMenuViewModel, lambda: PyMenuViewModel() )
Subscriber().setClassAllocator( PyFriendsViewModel, lambda: PyFriendsViewModel(FriendsService()) )


