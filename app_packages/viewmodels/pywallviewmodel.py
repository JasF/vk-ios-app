from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
from services.wallservice import WallService
import vk

class PyWallViewModel(ObjCBridgeProtocol):
    def __init__(self, wallService, parameters):
        self.wallService = wallService
        self.userId = parameters.get('userId')
        if self.userId == None or self.userId == 0:
            self.userId = vk.userId()
    
    # protocol methods implementation
    def getWall(self, offset):
        response = self.wallService.getWall(offset, self.userId)
        return response
    
    def getUserInfo(self):
        return self.wallService.getUserInfo()
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()

    def tappedOnPostWithId(self, identifier):
        managers.shared().screensManager().showWallPostViewController_(args=[identifier])

    # ObjCBridgeProtocol
    def release(self):
        pass
