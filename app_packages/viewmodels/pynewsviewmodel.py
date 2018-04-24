from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
from services.wallservice import WallService
import vk

class PyNewsViewModel(ObjCBridgeProtocol):
    def __init__(self, newsService):
        self.newsService = newsService
        self.userId = vk.userId()
    
    # protocol methods implementation
    def getNews(self, offset):
        response = self.newsService.getNews(offset)
        return response
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()
    
    # ObjCBridgeProtocol
    def release(self):
        pass
