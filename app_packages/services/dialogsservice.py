import vk
from vk import Session
import json
from caches.users import UsersDatabase

class DialogsServiceHandlerProtocol:
    def getDialogs(self, offset):
        users = UsersDatabase()
        session = vk.Session(access_token=vk.token())
        api = vk.API(session)
        api.session.method_default_args['v'] = '5.74'
        response = None
        usersData = None
        try:
            response = api.messages.getDialogs(access_token=vk.token(), offset=offset)
            l = response["items"]
            print('response: ' + str(response))
            userIds = set([d['message']['user_id'] for d in l])
            usersData = users.getShortUsersByIds(ids)
            fetchedIds = set([d['id'] for d in usersData])
            ids = ids - fetchedIds
            if len(ids):
                idsString = ', '.join(str(e) for e in ids)
                freshUsersData = api.users.get(user_ids=idsString, fields='photo_100')
                users.update(freshUsersData)
                usersData.extend(freshUsersData)
        except Exception as e:
            print('get dialogs exception: ' + str(e))
        return {'response':response, 'users':usersData}

