from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
from services.wallservice import WallService
import vk, json

class PyDocumentsViewModel(ObjCBridgeProtocol):
    def __init__(self, videosService, ownerId):
        self.videosService = videosService
        self.ownerId = ownerId
        self.endReached = False
    
    # protocol methods implementation
    def getDocuments(self, offset):
        if self.endReached:
            return {}
        
        response, count = self.videosService.getDocuments(self.ownerId, offset)
        if count == 0:
            self.endReached = True
        print('getDocuments response: ' + json.dumps(response))
        return response
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()
    
    # ObjCBridgeProtocol
    def release(self):
        pass
