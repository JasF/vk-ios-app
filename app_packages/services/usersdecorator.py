import vk
import json
from vk import users
import traceback
from vk import users as users

class UsersDecorator:
    def usersDataFromPosts(self, l):
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
        return usersData
