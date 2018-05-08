import vk
import json
from caches.usersdatabase import UsersDatabase
import traceback

class Users():
    def __init__(self):
        self.api = None
    
    def initializeSession(self):
        if self.api:
            return
        self.api = vk.api()
    
    def getShortUsersByIds(self, ids):
        idsSet = ids if isinstance(ids, set) else set(ids)
        result = self.getFieldsByIds(idsSet, fields='photo_100')
        if isinstance(ids, list):
            result = sorted(result,key=lambda x:ids.index(x['id']))
        return result
    
    def getShortUserById(self, id):
        l = self.getShortUsersByIds([id])
        if len(l) > 0:
            return l[0]
        return {}

    def getBigFieldsById(self, id, fields):
        users = UsersDatabase()
        userInfo = {}
        if id:
            self.initializeSession()
            
            scriptCode = """var friends = API.friends.get({ "count": 1, "user_id": {0} });
            var photos = API.photos.getAll({ "count": 0, "user_id": {0} });
            var video = API.video.get({ "owner_id": 0, "user_id": {0} });
            var users = API.users.getSubscriptions({ "count": 0, "user_id": {0}, "extended": 1});
            var groups = API.groups.get({ "count": 0, "user_id": {0} });
            var freshUsersData = API.users.get({"user_ids":"{0}", "fields":"{1}"});
            return {"friends_count": friends.count, "photos_count": photos.count, "videos_count": video.count, "subscriptions_count": users.count, "groups_count": groups.count, "user_info": freshUsersData};"""
            scriptCode = scriptCode.replace("{0}", str(id))
            scriptCode = scriptCode.replace("{1}", fields)
            response = self.api.execute(code=scriptCode)
            print('getBigFieldsById response: ' + str(response))
            freshUsersData = response.get('user_info')
            if len(freshUsersData) > 0:
                def s_set(k):
                    userInfo[k] = response.get(k)
                userInfo = freshUsersData[0]
                s_set('friends_count')
                s_set('photos_count')
                s_set('videos_count')
                s_set('subscriptions_count')
                s_set('groups_count')
                freshUsersData = [userInfo]
            if isinstance(freshUsersData, list):
                users.update(freshUsersData)
        users.close()
        return userInfo
        
    def getBigUserById(self, id):
        return self.getBigFieldsById(id, fields='photo_id, verified, sex, bdate, city, country, home_town, has_photo, photo_50, photo_100, photo_200_orig, photo_200, photo_400_orig, photo_max, photo_max_orig, online, domain, has_mobile, contacts, site, education, universities, schools, status, last_seen, followers_count, common_count, occupation, nickname, relatives, relation, personal, connections, exports, wall_comments, activities, interests, music, movies, tv, books, games, about, quotes, can_post, can_see_all_posts, can_see_audio, can_write_private_message, can_send_friend_request, is_favorite, is_hidden_from_feed, timezone, screen_name, maiden_name, crop_photo, is_friend, friend_status, career, military, blacklisted, blacklisted_by_me')
    
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
            #print('\n\n\n$$$$$self.api.users.get; ids: ' + str(idsString) + '\n\n\n')
            freshUsersData = self.api.users.get(user_ids=idsString, fields=fields)
            users.update(freshUsersData)
            usersData.extend(freshUsersData)
        
        if len(groupIds):
            self.initializeSession()
            idsString = ', '.join(str(e) for e in groupIds)
            freshGroupsData = self.api.groups.getById(group_ids=idsString,fields='cover,activity,status,counters')
            for d in freshGroupsData:
                d['id'] = -d['id']
            print('groups response:  ' + json.dumps(freshGroupsData, indent=4))
            users.update(freshGroupsData)
            usersData.extend(freshGroupsData)


        print(traceback.format_exc())

        users.close()
        return usersData

def getShortUsersByIds(ids):
    object = Users()
    return object.getShortUsersByIds(ids)

def getShortUserById(id):
    object = Users()
    return object.getShortUserById(id)

def getBigUserById(id):
    object = Users()
    return object.getBigUserById(id)
