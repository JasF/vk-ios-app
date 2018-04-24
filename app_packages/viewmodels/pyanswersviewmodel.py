from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
from services.wallservice import WallService
import vk

class PyAnswersViewModel(ObjCBridgeProtocol):
    def __init__(self, answersService):
        self.answersService = answersService
    
    # protocol methods implementation
    def getAnswers(self, offset):
        response = self.answersService.getAnswers(offset)
        print('response is: ' + str(response))
        return response
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()
    
    # ObjCBridgeProtocol
    def release(self):
        pass
