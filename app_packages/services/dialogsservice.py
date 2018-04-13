import vk
import json
from vk import users as users

class DialogsServiceHandlerProtocol:
    def getDialogs(self, offset):
        api = vk.api()
        response = None
        usersData = None
        try:
            response = api.messages.getDialogs(access_token=vk.token(), offset=offset)
            l = response["items"]
            print('response: ' + str(response))
            ids = set([d['message']['user_id'] for d in l])
            usersData = users.getShortUsersByIds(ids)
        
        except Exception as e:
            print('get dialogs exception: ' + str(e))
        return {'response':response, 'users':usersData}

