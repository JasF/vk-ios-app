import vk
import json
from vk import users
import traceback
from vk import users

g_count = 40

class BlackListService:
    def __init__(self):
        pass
    
    def getBanned(self, offset):
        response = None
        count = 0
        try:
            api = vk.api()
            response = api.account.getBanned(offset=offset, count=g_count)
            l = response['items']
            count = len(l)
            ids = [d['id'] for d in l]
            usersData = users.getShortUsersByIds(set(ids))
            response['items'] = usersData
            print('getBanned response is: ' + json.dumps(response, indent=4))
        except Exception as e:
            print('getBanned exception: ' + str(e))
            print(traceback.format_exc())
        return response, count
