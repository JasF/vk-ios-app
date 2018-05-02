import vk
import json
from vk import users
import traceback
from vk import users

class CreatePostService:
    def __init__(self):
        pass

    def createPost(self, ownerId, text):
        response = None
        try:
            api = vk.api()
            response = api.wall.post(owner_id=ownerId, message=text)
        except Exception as e:
            print('CreatePostService exception: ' + str(e))
        return response
