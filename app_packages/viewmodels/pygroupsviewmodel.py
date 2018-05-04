from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
from services.wallservice import WallService
import vk, json

class PyGroupsViewModel(ObjCBridgeProtocol):
    def __init__(self, groupsService, userId):
        self.groupsService = groupsService
        self.userId = userId
        self.endReached = False
        print('PyGroupsViewModel userId: ' + str(self.userId))
    
    # protocol methods implementation
    def getGroups(self, offset):
        if self.endReached:
            return {}
        
        response, count = self.groupsService.getGroups(self.userId, offset)
        if count == 0:
            self.endReached = True
        return response
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()
    
    def tappedOnGroupWithId(self, groupId):
        print('tappedOnGroupWithId: ' + str(groupId))
        managers.shared().screensManager().showWallViewController_push_(args=[groupId, True])
    
    # ObjCBridgeProtocol
    def release(self):
        pass
