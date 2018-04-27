import vk
import json
import traceback
from vk import users as users
from caches.postsdatabase import PostsDatabase

class GroupsService:
    def __init__(self, usersDecorator):
        self.usersDecorator = usersDecorator
        pass
    
    def getGroups(self, userId, offset):
        api = vk.api()
        response = None
        usersData = None
        count = 0
        try:
            response = api.groups.get(user_id=userId, offset=offset)
            l = response['items']
            count = len(l)
            gl = [-id for id in l]
            response['items'] = gl
            usersData = users.getShortUsersByIds(set(gl))
        except Exception as e:
            print('groups.get exception: ' + str(e))
        return {'response': response, 'users': usersData}, count
