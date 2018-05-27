from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
from services.wallservice import WallService
import vk, json
import analytics
from requests.exceptions import ConnectionError

class PyGroupsViewModel(ObjCBridgeProtocol):
    def __init__(self, groupsService, userId):
        self.groupsService = groupsService
        self.userId = userId
        self.endReached = False
        print('PyGroupsViewModel userId: ' + str(self.userId))
    
    # protocol methods implementation
    def getGroups(self, offset):
        response = {}
        if self.endReached:
            return response
        try:
            response, count = self.groupsService.getGroups(self.userId, offset)
            if count == 0:
                self.endReached = True
        except ConnectionError as e:
            return {'error':{'type':'connection'}}
        return response
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()
    
    def tappedOnGroupWithId(self, groupId):
        print('tappedOnGroupWithId: ' + str(groupId))
        analytics.log('Groups_segue')
        managers.shared().screensManager().showWallViewController_push_(args=[groupId, True])
    
    # ObjCBridgeProtocol
    def release(self):
        pass
