from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
from services.wallservice import WallService
import vk, json

class PyBookmarksViewModel(ObjCBridgeProtocol):
    def __init__(self, bookmarksService):
        self.bookmarksService = bookmarksService
        self.endReached = False
    
    # protocol methods implementation
    def getBookmarks(self, offset):
        if self.endReached:
            return {}
        
        response, count = self.bookmarksService.getBookmarks(offset)
        if count == 0:
            self.endReached = True
        print('getBookmarks response: ' + json.dumps(response))
        return response
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()
    
    # ObjCBridgeProtocol
    def release(self):
        pass
