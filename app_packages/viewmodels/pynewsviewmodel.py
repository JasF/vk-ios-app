from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
from services.wallservice import WallService
import vk
from requests.exceptions import ConnectionError

class PyNewsViewModel(ObjCBridgeProtocol):
    def __init__(self, newsService):
        self.newsService = newsService
        self.userId = vk.userId()
        self.next_from = None
        self.endReached = False
    
    # protocol methods implementation
    def getNews(self, offset):
        if self.endReached == True:
            return {}
        try:
            response, next_from = self.newsService.getNews(offset, self.next_from)
            if isinstance(next_from, str):
                self.next_from = next_from
            else:
                self.endReached = True
        except ConnectionError as e:
            return {'error':{'type':'connection'}}
        except Exception as e:
            print('getNews exception: ' + str(e))
        return response
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()
 
    # ObjCBridgeProtocol
    def release(self):
        pass
