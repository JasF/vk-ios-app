from .messagesdatabase import MessagesDatabase
from .usersdatabase import UsersDatabase
from .friendsdatabase import FriendsDatabase
from .postsdatabase import PostsDatabase
from .commentsdatabase import CommentsDatabase
from .photoalbumsdatabase import PhotoAlbumsDatabase
from .photosdatabase import PhotosDatabase
from .videosdatabase import VideosDatabase
from .documentsdatabase import DocumentsDatabase

def cleanDatabases():
    MessagesDatabase.deleteDatabaseFile(MessagesDatabase)
    UsersDatabase.deleteDatabaseFile(UsersDatabase)
    FriendsDatabase.deleteDatabaseFile(FriendsDatabase)
    PostsDatabase.deleteDatabaseFile(PostsDatabase)
    PhotoAlbumsDatabase.deleteDatabaseFile(PhotoAlbumsDatabase)
    PhotosDatabase.deleteDatabaseFile(PhotosDatabase)
    VideosDatabase.deleteDatabaseFile(VideosDatabase)
    DocumentsDatabase.deleteDatabaseFile(DocumentsDatabase)

cleanDatabases()
