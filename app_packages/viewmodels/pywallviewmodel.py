from objc import managers
from services.wallservice import WallService
import vk

class PyWallViewModel():
    def __init__(self, wallService, parameters):
        self.wallService = wallService
        self.userId = parameters.get('userId')
        if self.userId == None or self.userId == 0:
            self.userId = vk.userId()
    
    # protocol methods implementation
    def getWall(self, offset):
        return self.wallService.getWall(offset, self.userId)
    
    def getUserInfo(self):
        return self.wallService.getUserInfo()
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()

