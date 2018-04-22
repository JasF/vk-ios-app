from objc import managers
from services.wallservice import WallService

class PyWallViewModel():
    def __init__(self, wallService):
        self.wallService = wallService
        self.userInfo = None
    
    # protocol methods implementation
    def getWall(self, offset):
        return self.wallService.getWall(offset)
    
    def getUserInfo(self):
        return self.wallService.getUserInfo()
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()

