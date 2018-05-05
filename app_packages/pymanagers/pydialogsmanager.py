from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
from services.wallservice import WallService
import vk

class PyDialogsManagerDelegate(BridgeBase):
    pass

class PyDialogsManager(ObjCBridgeProtocol):
    def __new__(cls):
        if not hasattr(cls, 'instance') or not cls.instance:
            cls.instance = super().__new__(cls)
        return cls.instance

    def setDelegateId(self, delegateId):
        self.guiDelegate = PyDialogsManagerDelegate(delegateId)
    
    # ObjCBridgeProtocol
    def release(self):
        pass

    def showTextFieldDialogWithText(self, text):
        text, cancelled = self.guiDelegate.showTextFieldDialogWithText_(args=[text], withResult=True)
        return text, cancelled
    
    def showRowsDialogWithTitles(self, titles):
        index, cancelled = self.guiDelegate.showRowsDialogWithTitles_(args=[titles], withResult=True)
        return index, cancelled

    def showDialogWithMessage(self, message):
        self.guiDelegate.showDialogWithMessage_(args=[message])
