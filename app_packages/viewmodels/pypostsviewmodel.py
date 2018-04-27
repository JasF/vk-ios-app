from objc import managers
from services.wallservice import WallService
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk, json
from caches.postsdatabase import PostsDatabase
import threading
from pymanagers.pydialogsmanager import PyDialogsManager

# https://vk.com/dev/wall.getComments
class PyPostsViewModel(ObjCBridgeProtocol):
    def __init__(self):
        print('\n\n\nPyPostsViewModel allocated\n\n\n')

    def likeObjectWithTypeownerIditemIdaccessKeylike(self, type, ownerId, itemId, accessKey, like):
        try:
            api = vk.api()
            if like == True:
                response = api.likes.add(type=type, owner_id=ownerId, item_id=itemId, access_key=accessKey)
            else:
                response = api.likes.delete(type=type, owner_id=ownerId, item_id=itemId)
            
            def updateCache():
                likesCount = response.get('likes')
                if isinstance(likesCount, int):
                    cache = PostsDatabase()
                    data = cache.getById(ownerId, itemId)
                    likes = data['likes']
                    likes['count'] = likesCount
                    likes['user_likes'] = 1 if like == True else 0
                    data['likes'] = likes
                    cache.update([data])
                    cache.close()
                        
            thread = threading.Thread(target=updateCache)
            thread.start()
                
        except Exception as e:
            print('likeObjectWithTypeownerIditemIdaccessKeylike exception: ' + str(e))
        return response
    
    def doRepostForFriends(self, identifier, message):
        if not isinstance(message, str):
            message = ''
        try:
            api = vk.api()
            response = api.wall.repost(object=identifier, message=message)
            print('doRepostForFriends response: ' + json.dumps(response))
            '''
            def updateCache():
                likesCount = response.get('likes')
                if isinstance(likesCount, int):
                    cache = PostsDatabase()
                    data = cache.getById(ownerId, itemId)
                    likes = data['likes']
                    likes['count'] = likesCount
                    likes['user_likes'] = 1 if like == True else 0
                    data['likes'] = likes
                    cache.update([data])
                    cache.close()
            thread = threading.Thread(target=updateCache)
            thread.start()
    
                '''
        except Exception as e:
            print('doRepostForFriends exception: ' + str(e))
        return response
    
    def repostObjectWithIdentifier(self, identifier):
        dialogsManager = PyDialogsManager()
        index, cancelled = dialogsManager.showRowsDialogWithTitles(['repost_for_friends', 'repost_as_message'])
        if cancelled:
            return {}
        if index == 0:
            text, cancelled = dialogsManager.showTextFieldDialogWithText('repost_enter_message')
            if cancelled:
                return {}
            return self.doRepostForFriends(identifier, text)
        return {}
    
    # ObjCBridgeProtocol
    def release(self):
        pass
