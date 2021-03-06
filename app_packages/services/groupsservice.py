import vk
import json
import traceback
from vk import users as users
from caches.postsdatabase import PostsDatabase
from requests.exceptions import ConnectionError

g_count = 40

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
            response = api.groups.get(user_id=userId, offset=offset, count=g_count)
            l = response['items']
            #print('groups.get response is: ' + json.dumps(response, indent=4))
            count = len(l)
            gl = [-id for id in l]
            response['items'] = gl
            usersData = users.getShortUsersByIds(set(gl))
        except ConnectionError as e:
            raise e
        except Exception as e:
            print('groups.get exception: ' + str(e))
        return {'response': response, 'users': usersData}, count

