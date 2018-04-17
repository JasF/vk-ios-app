from objc import managers
from services.wallservice import WallService

class PyWallScreenViewModel():
    def __init__(self, wallService):
        self.wallService = wallService
    
    # protocol methods implementation
    def getWall(self, offset):
        return self.wallService.getWall(offset)
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()

