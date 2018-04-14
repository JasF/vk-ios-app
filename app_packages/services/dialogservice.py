import vk
import json
from vk import users as users
from caches.messages import MessagesDatabase

class DialogServiceHandlerProtocol:
    def getMessagesuserId(self, offset, userId):
        print('offset: ' + str(offset) + '; userId: ' + str(userId))
        api = vk.api()
        response = None
        usersData = None
        try:
            response = api.messages.getHistory(access_token=vk.token(), user_id=userId, offset=offset, count=20)
            l = response["items"]
            #print('response messages: ' + json.dumps(response))
            
            # AV: Put messages to database
            messages = MessagesDatabase()
            messages.update(l)
            messages.close()
        
        except Exception as e:
            print('get messages exception: ' + str(e))
        return {'response':response, 'users':usersData}

