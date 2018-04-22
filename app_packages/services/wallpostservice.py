import vk
import json
from vk import users
import traceback
from vk import users as users
from caches.postsdatabase import PostsDatabase


class WallPostService:
    def __init__(self):
        pass

    def getPostById(self, identifier):
        cache = PostsDatabase()
        result = cache.getById(identifier)
        cache.close()
        return result
