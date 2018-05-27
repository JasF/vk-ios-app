import vk
import json
from vk import users as users
from constants import g_LoadingElements
from requests.exceptions import ConnectionError

class ChatListService:
    def getDialogs(self, offset):
        api = vk.api()
        response = None
        usersData = None
        try:
            response = api.messages.getDialogs(offset=offset, count=g_LoadingElements)
            l = response["items"]
            #print('response dialogs: ' + json.dumps(response, indent=4))
            ids = set([d['message']['user_id'] for d in l])
            usersData = users.getShortUsersByIds(ids)
        except ConnectionError as e:
            raise e
        except Exception as e:
            print('get dialogs exception: ' + str(e))
        return {'response':response, 'users':usersData}

