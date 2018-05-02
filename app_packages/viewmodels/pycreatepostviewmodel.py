from objc import managers
from services.wallservice import WallService
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk, json
from vk import users
from pymanagers.pydialogsmanager import PyDialogsManager

class PyCreatePostViewModel():
    def __init__(self, createPostService, ownerId):
        self.createPostService = createPostService
        self.ownerId = ownerId
    
    # protocol methods implementation
    def createPost(self, text):
        results = self.createPostService.createPost(self.ownerId, text)
        postId = 0
        try:
            postId = results['post_id']
        except:
            pass
        if postId == 0:
            dialogsManager = PyDialogsManager()
            dialogsManager.showDialogWithMessage('error_create_post')
        else:
            managers.shared().screensManager().dismissCreatePostViewController_(args=[True])
        return postId

    # ObjCBridgeProtocol
    def release(self):
        pass
