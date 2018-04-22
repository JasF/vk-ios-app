import vk
import json
from vk import users
import traceback
from vk import users as users

class WallService:
    def __init__(self, parameters):
        self.userInfo = None
        print('WallService parameters: ' + str(parameters))
        self.userId = parameters.get('userId')
        if self.userId == None or self.userId == 0:
            self.userId = vk.userId()
    
    def getWall(self, offset, userId):
        api = vk.api()
        response = None
        usersData = None
        try:
            response = api.wall.get(offset=offset, owner_id=userId)
            l = response["items"]
            
            fromIds = [d['from_id'] for d in l]
            ownerIds = [d['owner_id'] for d in l]
            
            def getId(object, key):
                if isinstance(object, list):
                    return [d.get(key) for d in object]
                return None
            
            historyFromIds = [getId(d.get('copy_history'), 'owner_id') for d in l if getId(d.get('copy_history'), 'owner_id')]
            historyOwnerIds = [getId(d.get('copy_history'), 'from_id') for d in l if getId(d.get('copy_history'), 'from_id')]
            
            historyFromIds = [item for sublist in historyFromIds for item in sublist]
            historyOwnerIds = [item for sublist in historyOwnerIds for item in sublist]
            
            ids = set()
            ids |= set(fromIds)
            ids |= set(ownerIds)
            ids |= set(historyFromIds)
            ids |= set(historyOwnerIds)
            
            usersData = users.getShortUsersByIds(ids)
        
        except Exception as e:
            print('wall.get exception: ' + str(e))
        results = {'response':response, 'users':usersData}
        return results
    
    # private
    def getUserInfo(self):
        if self.userInfo == None:
            usersInfo = users.getShortUsersByIds(set([self.userId]))
            if len(usersInfo) > 0:
                print('set userInfo may be slowly on poor connection and startup breaking')
                self.userInfo = usersInfo[0]
        return self.userInfo
