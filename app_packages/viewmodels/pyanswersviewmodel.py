from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
from services.wallservice import WallService
import vk, json

class PyAnswersViewModel(ObjCBridgeProtocol):
    def __init__(self, answersService):
        self.answersService = answersService
        self.next_from = None
        self.endReached = False
    
    # protocol methods implementation
    def getAnswers(self, offset):
        if self.endReached == True:
            return {}
        
        response, next_from = self.answersService.getAnswers(offset, self.next_from)
        if isinstance(next_from, str):
            self.next_from = next_from
        else:
            self.endReached = True
        return response
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()
    
    # ObjCBridgeProtocol
    def release(self):
        pass
