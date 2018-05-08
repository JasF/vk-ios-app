import vk
import json
from vk import users as users

class ChatListService:
    def getDialogs(self, offset):
        api = vk.api()
        response = None
        usersData = None
        try:
            response = api.messages.getDialogs(offset=offset)
            l = response["items"]
            #print('response dialogs: ' + json.dumps(response, indent=4))
            ids = set([d['message']['user_id'] for d in l])
            usersData = users.getShortUsersByIds(ids)
        
        except Exception as e:
            print('get dialogs exception: ' + str(e))
        return {'response':response, 'users':usersData}

