from objcbridge import BridgeBase, Subscriber
from viewmodels.pydialogscreenviewmodel import PyDialogScreenViewModel
from .pychatlistviewmodel import PyChatListViewModel
from .pywallviewmodel import PyWallViewModel
from .pymenuviewmodel import PyMenuViewModel
from .pyfriendsviewmodel import PyFriendsViewModel
from .pywallpostviewmodel import PyWallPostViewModel
from .pyphotoalbumsviewmodel import PyPhotoAlbumsViewModel
from .pygalleryviewmodel import PyGalleryViewModel
from .pyimagesviewerviewmodel import PyImagesViewerViewModel
from .pynewsviewmodel import PyNewsViewModel
from .pyanswersviewmodel import PyAnswersViewModel

from services.messagesservice import MessagesService
from services.chatlistservice import ChatListService
from services.dialogservice import DialogService
from services.wallservice import WallService
from services.wallpostservice import WallPostService
from services.friendsservice import FriendsService
from services.usersdecorator import UsersDecorator
from services.photoalbumsservice import PhotoAlbumsService
from services.galleryservice import GalleryService
from services.newsservice import NewsService
from services.answersservice import AnswersService

Subscriber().setClassAllocatorWithDelegate( PyChatListViewModel, lambda delegateId: PyChatListViewModel(delegateId, MessagesService(), ChatListService()) )
Subscriber().setClassAllocatorWithDelegate( PyDialogScreenViewModel, lambda delegateId, parameters: PyDialogScreenViewModel(delegateId, parameters, MessagesService(), DialogService()) )
Subscriber().setClassAllocatorWithDelegate( PyWallViewModel, lambda delegateId, parameters: PyWallViewModel(WallService(parameters.get('userId'), UsersDecorator()), parameters) )
Subscriber().setClassAllocator( PyNewsViewModel, lambda: PyNewsViewModel(NewsService(UsersDecorator())) )
Subscriber().setClassAllocator( PyMenuViewModel, lambda: PyMenuViewModel() )
Subscriber().setClassAllocator( PyPhotoAlbumsViewModel, lambda parameters: PyPhotoAlbumsViewModel(PhotoAlbumsService(), parameters['ownerId']) )
Subscriber().setClassAllocator( PyGalleryViewModel, lambda parameters: PyGalleryViewModel(GalleryService(), parameters['ownerId'], parameters['albumId']) )
Subscriber().setClassAllocator( PyImagesViewerViewModel, lambda parameters: PyImagesViewerViewModel(GalleryService(), parameters['ownerId'], parameters['albumId'], parameters['photoId']) )
Subscriber().setClassAllocator( PyFriendsViewModel, lambda: PyFriendsViewModel(FriendsService()) )
Subscriber().setClassAllocatorWithDelegate( PyWallPostViewModel, lambda delegateId, parameters: PyWallPostViewModel(WallPostService(UsersDecorator()), parameters['ownerId'], parameters['postId']) )
Subscriber().setClassAllocator( PyAnswersViewModel, lambda: PyAnswersViewModel(AnswersService()) )
