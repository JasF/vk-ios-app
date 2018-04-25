from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
from services.wallservice import WallService
import vk, json

class PySettingsViewModel(ObjCBridgeProtocol):
    def getSettings(self):
        return {'notificationsEnabled': True}
    
    def menuTapped(self):
        managers.shared().screensManager().showMenu()
    
    def notificationsSettingsChanged(self, on):
        print('notificationsSettingsChanged: ' + str(on))
    # ObjCBridgeProtocol
    def release(self):
        pass
