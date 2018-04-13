import vk
from vk import Session
import json
from caches.users import UsersDatabase

class Users():
    def __init__(self):
        self.api = None
        self.session = None
    
    def initializeSession(self):
        if self.api:
            return
        self.session = vk.Session(access_token=vk.token())
        self.api = vk.API(self.session)
        self.api.session.method_default_args['v'] = '5.74'
    
    def getUsersByIds(self, ids):
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

        print('users.py usersData: ' + str(usersData))
        return usersData

def getUsersByIds(ids):
    object = Users()
    return object.getUsersByIds(ids)
