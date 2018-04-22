from objcbridge import BridgeBase, Subscriber
from viewmodels.pydialogscreenviewmodel import PyDialogScreenViewModel
from .pychatlistviewmodel import PyChatListViewModel
from .pywallviewmodel import PyWallViewModel
from .pymenuviewmodel import PyMenuViewModel
from .pyfriendsviewmodel import PyFriendsViewModel
from .pywallpostviewmodel import PyWallPostViewModel

from services.messagesservice import MessagesService
from services.chatlistservice import ChatListService
from services.dialogservice import DialogService
from services.wallservice import WallService
from services.friendsservice import FriendsService

Subscriber().setClassAllocatorWithDelegate( PyChatListViewModel, lambda delegateId: PyChatListViewModel(delegateId, MessagesService(), ChatListService()) )
Subscriber().setClassAllocatorWithDelegate( PyDialogScreenViewModel, lambda delegateId, parameters: PyDialogScreenViewModel(delegateId, parameters, MessagesService(), DialogService()) )
Subscriber().setClassAllocatorWithDelegate( PyWallViewModel, lambda delegateId, parameters: PyWallViewModel(WallService(parameters), parameters) )
Subscriber().setClassAllocator( PyMenuViewModel, lambda: PyMenuViewModel() )
Subscriber().setClassAllocator( PyFriendsViewModel, lambda: PyFriendsViewModel(FriendsService()) )
Subscriber().setClassAllocatorWithDelegate( PyWallPostViewModel, lambda delegateId, parameters: PyWallPostViewModel(WallService(parameters), parameters) )
