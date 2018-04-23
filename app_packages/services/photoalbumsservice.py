import vk
import json
from vk import users
import traceback
from caches.postsdatabase import PostsDatabase
from caches.commentsdatabase import CommentsDatabase

g_count = 40

class PhotoAlbumsService:
    def __init__(self):
        pass

    def getPhotoAlbums(self, ownerId, offset):
        api = vk.api()
        response = None
        try:
            response = api.photos.getAlbums(owner_id=ownerId, offset=offset, count=g_count, need_system=1, need_covers=1)
        except Exception as e:
            print('getPhotoAlbums exception: ' + str(e))
        return response

