import vk
import json
from vk import users
import traceback

class WallService:
    def getWall(self, offset):
        api = vk.api()
        response = None
        usersData = None
        try:
            response = api.wall.get(offset=offset)
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
        return {'response':response, 'users':usersData}
