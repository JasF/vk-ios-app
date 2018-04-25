import vk
import json
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
        #print('historySourceIds: ' + str(historySourceIds))
        return usersData


    def usersDataFromAnswers(self, l):
        userIds = []
        for d in l:
            type = d.get('type')
            if type in ['like_post', 'like_photo', 'like_comment']:
                userIds.extend([d.get('from_id') for d in d.get('feedback').get('items') if d.get('from_id')])
            elif type == 'reply_comment' or type == 'comment_post':
                fromId = d.get('feedback').get('from_id')
                if fromId:
                    userIds.append(fromId)
       
        ids = set(userIds)
        usersData = users.getShortUsersByIds(ids)
        return usersData
