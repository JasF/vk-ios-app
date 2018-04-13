import vk
from vk import Session
import json
from caches.users import UsersDatabase

class WallServiceHandlerProtocol:
    def getWall(self, offset):
        users = UsersDatabase()
        session = vk.Session(access_token=vk.token())
        api = vk.API(session)
        api.session.method_default_args['v'] = '5.74'
        response = None
        usersData = None
        try:
            response = api.wall.get(access_token=vk.token(), offset=offset)
            l = response["items"]
            
            print('item is: ' + str(l[0]))
            
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
                idsString = ', '.join(str(e) for e in ids)
                freshUsersData = api.users.get(user_ids=idsString, fields='photo_100')
                users.update(freshUsersData)
                usersData.extend(freshUsersData)
            
            if len(groupIds):
                idsString = ', '.join(str(e) for e in groupIds)
                freshGroupsData = api.groups.getById(group_ids=idsString)
                users.update(freshGroupsData)
                usersData.extend(freshGroupsData)
        
        except Exception as e:
            print('wall.get exception: ' + str(e))
        finally:
            users.close()
        return {'response':response, 'users':usersData}
