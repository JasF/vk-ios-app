from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
from services.wallservice import WallService
import vk, json
from .pyfriendsviewmodel import UsersListTypes
from pymanagers.pydialogsmanager import PyDialogsManager

g_WallPostsCount = 20

class PyWallViewModelDelegate(BridgeBase):
    pass

class PyWallViewModel(ObjCBridgeProtocol):
    def __init__(self, wallService, parameters, delegateId):
        self.wallService = wallService
        self.userId = parameters.get('userId')
        self.guiDelegate = PyWallViewModelDelegate(delegateId)
        if self.userId == None or self.userId == 0:
            self.userId = vk.userId()
    
    # protocol methods implementation
    def getWallcount(self, offset, count):
        if count == 0:
            count = g_WallPostsCount
        response = self.wallService.getWall(offset, self.userId, count)
        return response
    
    def getUserInfo(self):
        if self.userId <0:
            results = self.wallService.getUserInfo()
            #print('getUserInfo result: ' + json.dumps(results, indent=4))
            return results
        elif self.userId > 0:
            results = self.wallService.getBigUserInfo()
            return results

    def menuTapped(self):
        managers.shared().screensManager().showMenu()

    def friendsTapped(self):
        managers.shared().screensManager().showFriendsViewController_usersListType_(args=[self.userId, UsersListTypes.FRIENDS])

    def commonTapped(self):
        pass

    def subscribtionsTapped(self):
        managers.shared().screensManager().showFriendsViewController_usersListType_(args=[self.userId, UsersListTypes.SUBSCRIPTIONS])
    
    def followersTapped(self):
        managers.shared().screensManager().showFriendsViewController_usersListType_(args=[self.userId, UsersListTypes.FOLLOWERS])

    def photosTapped(self):
        managers.shared().screensManager().showPhotoAlbumsViewController_push_(args=[self.userId, True])

    def videosTapped(self):
        managers.shared().screensManager().showVideosViewController_push_(args=[self.userId, True])
    
    def groupsTapped(self):
        managers.shared().screensManager().showGroupsViewController_push_(args=[self.userId, True])

    def messageButtonTapped(self):
        managers.shared().screensManager().showDialogViewController_(args=[self.userId])
    
    def addPostTapped(self):
        managers.shared().screensManager().presentAddPostViewController_(args=[self.userId])
    
    def friendButtonTapped(self, friend_status):
        response = {}
        try:
            api = vk.api()
            if self.userId < 0:
                # работа с группой
                return self.joinOrLeaveGroup(friend_status)
            elif friend_status == 1 or friend_status == 3:
                if friend_status == 3:
                    # Пользователь друг или есть входящая заявка
                    dialogsManager = PyDialogsManager()
                    index, cancelled = dialogsManager.showRowsDialogWithTitles(['delete_from_friends'])
                    if cancelled:
                        return -1
                response = api.friends.delete(user_id=self.userId)
                print('friends.delete response: ' + str(response))
                if response.get('success') == 1:
                    return 5 if friend_status == 3 else 0
                return -1
            response = api.friends.add(user_id=self.userId)
        except Exception as e:
            print('wallviewmodel.py friendButtonTapped exception: ' + str(e))
        return response
            
    def joinOrLeaveGroup(self, is_member):
        response = {}
        try:
            api = vk.api()
            if is_member == 0:
                response = api.groups.join(group_id=abs(self.userId))
            else:
                response = api.groups.leave(group_id=abs(self.userId))
        except Exception as e:
            print('wallviewmodel.py joinOrLeaveGroup exception: ' + str(e))
        return response
    
        
    # ObjCBridgeProtocol
    def release(self):
        pass
