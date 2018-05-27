from objc import managers
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk, json
from vk import users
from pymanagers.pydialogsmanager import PyDialogsManager

class PyBlackListViewModelDelegate(BridgeBase):
    pass

class PyBlackListViewModel(ObjCBridgeProtocol):
    def __init__(self, blackListService, delegateId):
        self.service = blackListService
        self.endReached = False
        self.guiDelegate = PyBlackListViewModelDelegate(delegateId)
    
    def getBanned(self, offset):
        if self.endReached:
            return {}
        response, count = self.service.getBanned(offset)
        if count == 0:
            self.endReached = True
        return response
    
    def unbanUser(self, userId):
        userData = users.getShortUserById(userId)
        first_name = userData.get('first_name')
        last_name = userData.get('last_name')
        if userId < 0:
            first_name = userData.get('name')
        userName = ""
        if not isinstance(first_name, str) and not isinstance(last_name, str):
            print('name not defined for userData: ' + json.dumps(userData, indent=4))
            return False
        elif isinstance(first_name, str) and isinstance(last_name, str):
            userName = first_name + ' ' + last_name
        elif isinstance(first_name, str):
            userName = first_name
        else:
            userName = last_name

        locString = self.guiDelegate.localize_(args=['are_you_sure_for_unblock_username'], withResult=True) + userName + self.guiDelegate.localize_(args=['are_you_sure_for_unblock_username_tile'], withResult=True)
        dialogsManager = PyDialogsManager()
        index, cancelled = dialogsManager.showYesNoDialogWithMessage(locString, "unban_user_button", "cancel")
        if cancelled == True:
            return False
        return self.doUnbanUser(userId)
    
    def doUnbanUser(self, userId):
        result = 0
        try:
            api = vk.api()
            result = api.account.unban(owner_id=userId)
        except Exception as e:
            print('unbanUser exception: ' + str(e))
        
        if not isinstance(result, int) or result != 1:
            message = 'error_unban_user' if userId>0 else 'error_unban_group'
            dialogsManager = PyDialogsManager()
            dialogsManager.showDialogWithMessage(message)
            return False
        return True

    def tappedWithUserId(self, userId):
        managers.shared().screensManager().showWallViewController_push_(args=[userId, True])
    
    # ObjCBridgeProtocol
    def release(self):
        pass
