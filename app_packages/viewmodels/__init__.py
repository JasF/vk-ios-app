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
from .pygroupsviewmodel import PyGroupsViewModel
from .pybookmarksviewmodel import PyBookmarksViewModel
from .pyvideosviewmodel import PyVideosViewModel
from .pydocumentsviewmodel import PyDocumentsViewModel
from .pysettingsviewmodel import PySettingsViewModel
from .pydetailphotoviewmodel import PyDetailPhotoViewModel
from .pyauthorizationviewmodel import PyAuthorizationViewModel
from .pydetailvideoviewmodel import PyDetailVideoViewModel
from .pypostsviewmodel import PyPostsViewModel
from .pycreatepostviewmodel import PyCreatePostViewModel
from .pymwphotobrowserviewmodel import PyMWPhotoBrowserViewModel

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
from services.groupsservice import GroupsService
from services.bookmarksservice import BookmarksService
from services.videosservice import VideosService
from services.documentsservice import DocumentsService
from services.detailphotoservice import DetailPhotoService
from services.detailvideoservice import DetailVideoService
from services.commentsservice import CommentsService
from services.createpostservice import CreatePostService

Subscriber().setClassAllocatorWithDelegate( PyChatListViewModel, lambda delegateId: PyChatListViewModel(delegateId, MessagesService(), ChatListService()) )
Subscriber().setClassAllocatorWithDelegate( PyDialogScreenViewModel, lambda delegateId, parameters: PyDialogScreenViewModel(delegateId, parameters, MessagesService(), DialogService()) )
Subscriber().setClassAllocatorWithDelegate( PyWallViewModel, lambda delegateId, parameters: PyWallViewModel(WallService(parameters.get('userId'), UsersDecorator()), parameters, delegateId) )
Subscriber().setClassAllocator( PyNewsViewModel, lambda: PyNewsViewModel(NewsService(UsersDecorator())) )
Subscriber().setClassAllocator( PyMenuViewModel, lambda: PyMenuViewModel() )
Subscriber().setClassAllocator( PyPhotoAlbumsViewModel, lambda parameters: PyPhotoAlbumsViewModel(PhotoAlbumsService(), parameters['ownerId']) )
Subscriber().setClassAllocator( PyGalleryViewModel, lambda parameters: PyGalleryViewModel(GalleryService(), parameters['ownerId'], parameters['albumId']) )
Subscriber().setClassAllocatorWithDelegate( PyImagesViewerViewModel, lambda delegate, parameters: PyImagesViewerViewModel(GalleryService(), delegate, parameters) )
Subscriber().setClassAllocator( PyDetailPhotoViewModel, lambda parameters: PyDetailPhotoViewModel(DetailPhotoService(UsersDecorator(), CommentsService()), parameters['ownerId'], parameters['photoId']) )
Subscriber().setClassAllocator( PyFriendsViewModel, lambda parameters: PyFriendsViewModel(FriendsService(), parameters['userId'], parameters['usersListType']) )
Subscriber().setClassAllocatorWithDelegate( PyWallPostViewModel, lambda delegateId, parameters: PyWallPostViewModel(WallPostService(UsersDecorator(), CommentsService()), parameters['ownerId'], parameters['postId']) )
Subscriber().setClassAllocator( PyAnswersViewModel, lambda: PyAnswersViewModel(AnswersService(UsersDecorator())) )
Subscriber().setClassAllocator( PyGroupsViewModel, lambda parameters: PyGroupsViewModel(GroupsService(UsersDecorator()), parameters.get('userId')) )
Subscriber().setClassAllocator( PyBookmarksViewModel, lambda: PyBookmarksViewModel(BookmarksService(UsersDecorator())) )
Subscriber().setClassAllocator( PyVideosViewModel, lambda parameters: PyVideosViewModel(VideosService(), parameters.get('ownerId')) )
Subscriber().setClassAllocator( PyDocumentsViewModel, lambda parameters: PyDocumentsViewModel(DocumentsService(), parameters.get('ownerId')) )
Subscriber().setClassAllocator( PySettingsViewModel, lambda: PySettingsViewModel() )
Subscriber().setClassAllocator( PyAuthorizationViewModel, lambda: PyAuthorizationViewModel() )
Subscriber().setClassAllocatorWithDelegate( PyDetailVideoViewModel, lambda delegateId, parameters: PyDetailVideoViewModel(DetailVideoService(UsersDecorator(), CommentsService()), delegateId, parameters['ownerId'], parameters['videoId']) )
Subscriber().setClassAllocatorWithDelegate( PyPostsViewModel, lambda delegateId: PyPostsViewModel(WallPostService(UsersDecorator(), CommentsService()), DetailPhotoService(UsersDecorator(), CommentsService()), DetailVideoService(UsersDecorator(), CommentsService())) )
Subscriber().setClassAllocator( PyCreatePostViewModel, lambda parameters: PyCreatePostViewModel(CreatePostService(), parameters['ownerId']) )
Subscriber().setClassAllocator( PyMWPhotoBrowserViewModel, lambda: PyMWPhotoBrowserViewModel() )
