from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk, json
from vk import users

class PyBlackListViewModel(ObjCBridgeProtocol):
    def __init__(self, blackListService):
        self.service = blackListService
        self.endReached = False
        pass
    
    def getBanned(self, offset):
        if self.endReached:
            return {}
        
        response, count = self.service.getBanned(offset)
        
        if count == 0:
            self.endReached = True
        return response
    
    # ObjCBridgeProtocol
    def release(self):
        pass
