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
        return self.getFieldsByIds(ids, fields='photo_100')
    
    def getBigFieldsByIds(self, ids,fields):
        users = UsersDatabase()
        usersData = []
        if len(ids):
            self.initializeSession()
            idsString = ', '.join(str(e) for e in ids)
            freshUsersData = self.api.users.get(user_ids=idsString, fields=fields)
            users.update(freshUsersData)
            usersData.extend(freshUsersData)
        users.close()
        return usersData
        

    def getBigUsersByIds(self, ids):
        return self.getBigFieldsByIds(ids, fields='photo_id, verified, sex, bdate, city, country, home_town, has_photo, photo_50, photo_100, photo_200_orig, photo_200, photo_400_orig, photo_max, photo_max_orig, online, domain, has_mobile, contacts, site, education, universities, schools, status, last_seen, followers_count, common_count, occupation, nickname, relatives, relation, personal, connections, exports, wall_comments, activities, interests, music, movies, tv, books, games, about, quotes, can_post, can_see_all_posts, can_see_audio, can_write_private_message, can_send_friend_request, is_favorite, is_hidden_from_feed, timezone, screen_name, maiden_name, crop_photo, is_friend, friend_status, career, military, blacklisted, blacklisted_by_me')
    
    def getFieldsByIds(self, ids, fields):
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
            freshUsersData = self.api.users.get(user_ids=idsString, fields=fields)
            users.update(freshUsersData)
            usersData.extend(freshUsersData)
        
        if len(groupIds):
            self.initializeSession()
            idsString = ', '.join(str(e) for e in groupIds)
            freshGroupsData = self.api.groups.getById(group_ids=idsString)
            for d in freshGroupsData:
                d['id'] = -d['id']
            users.update(freshGroupsData)
            usersData.extend(freshGroupsData)
        
        users.close()
        return usersData

def getShortUsersByIds(ids):
    object = Users()
    return object.getShortUsersByIds(ids)

def getBigUsersByIds(ids):
    object = Users()
    return object.getBigUsersByIds(ids)
