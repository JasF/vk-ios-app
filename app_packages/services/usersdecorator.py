import vk
import json
from vk import users
import traceback
from vk import users as users

class UsersDecorator:
    def usersDataFromPosts(self, l):
        fromIds = []
        ownerIds = []
        sourceIds = []
        friends = []
        try:
            fromIds = [d['from_id'] for d in l]
        except:
            pass
        try:
            ownerIds = [d['owner_id'] for d in l]
        except:
            pass
        try:
            sourceIds = [d['source_id'] for d in l]
        except:
            pass
        
        for d in l:
            if d.get('type') == 'friend':
                friends.extend([id.get('user_id') for id in d.get('friends').get('items') if isinstance(id.get('user_id'), int)])
        
        def getId(object, key):
            if isinstance(object, list):
                return [d.get(key) for d in object]
            return None
        
        historyFromIds = [getId(d.get('copy_history'), 'owner_id') for d in l if getId(d.get('copy_history'), 'owner_id')]
        historyOwnerIds = [getId(d.get('copy_history'), 'from_id') for d in l if getId(d.get('copy_history'), 'from_id')]
        historySourceIds = [getId(d.get('copy_history'), 'source_id') for d in l if getId(d.get('copy_history'), 'source_id')]
        
        historyFromIds = [item for sublist in historyFromIds for item in sublist]
        historyOwnerIds = [item for sublist in historyOwnerIds for item in sublist]
        historySourceIds = [item for sublist in historySourceIds for item in sublist]
        
        ids = set()
        ids |= set(fromIds)
        ids |= set(ownerIds)
        ids |= set(sourceIds)
        ids |= set(historyFromIds)
        ids |= set(historyOwnerIds)
        ids |= set(friends)
        #ids |= set(historySourceIds)
        
        usersData = users.getShortUsersByIds(ids)
        print('historySourceIds: ' + str(historySourceIds))
        return usersData
