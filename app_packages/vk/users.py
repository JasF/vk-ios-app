import vk
import json
from caches.usersdatabase import UsersDatabase

class Users():
    def __init__(self):
        self.api = None
    
    def initializeSession(self):
        if self.api:
            return
        self.api = vk.api()
    
    def getShortUsersByIds(self, ids):
        users = UsersDatabase()
        groupIds = set([id for id in ids if id < 0])
        ids -= groupIds
        groupIds = set([abs(id) for id in groupIds])
        
        usersData = users.getShortUsersByIds(ids)
        groupsData = users.getShortUsersByIds(groupIds)
        
        fetchedIds = set([d['id'] for d in usersData])
        ids = ids - fetchedIds
        
        fetchedGroupIds = set([d['id'] for d in groupsData])
        groupIds = groupIds - fetchedGroupIds
        
        usersData.extend(groupsData)
        
        if len(ids):
            self.initializeSession()
            idsString = ', '.join(str(e) for e in ids)
            freshUsersData = self.api.users.get(user_ids=idsString, fields='photo_100')
            users.update(freshUsersData)
            usersData.extend(freshUsersData)
        
        if len(groupIds):
            self.initializeSession()
            idsString = ', '.join(str(e) for e in groupIds)
            freshGroupsData = self.api.groups.getById(group_ids=idsString)
            users.update(freshGroupsData)
            usersData.extend(freshGroupsData)
        
        users.close()
        return usersData

def getShortUsersByIds(ids):
    object = Users()
    return object.getShortUsersByIds(ids)
