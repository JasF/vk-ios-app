from objc import managers
from services.wallservice import WallService
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk, json
from vk import users
from constants import g_CommentsCount
import threading

class PyDetailVideoViewModelDelegate(BridgeBase):
    pass

class PyDetailVideoViewModel():
    def __init__(self, detailVideoService, delegateId, ownerId, videoId):
        self.detailVideoService = detailVideoService
        self.ownerId = ownerId
        self.videoId = videoId
        print('PyDetailVideoViewModel ownerId: ' + str(ownerId) + '; videoId: ' + str(videoId))
        self.videoData = None
        self.userInfo = None
        self.guiDelegate = PyDetailVideoViewModelDelegate(delegateId)
    
    # protocol methods implementation
    def getVideoData(self, offset):
        results = {}
        if not self.videoData:
            self.userInfo = users.getShortUserById(self.ownerId)
            self.videoData = self.detailVideoService.getVideo(self.ownerId, self.videoId)
            comments = self.detailVideoService.getComments(self.ownerId, self.videoId, offset, g_CommentsCount)
            results['comments'] = comments
        if offset == 0:
            self.videoData['owner'] = self.userInfo
            results['videoData'] = self.videoData
        
        player = ""
        try:
            player = self.videoData['player']
        except:
            pass
        if not isinstance(player, str) or len(player) == 0:
            def updateVideo():
                dict = self.detailVideoService.updateVideo(self.ownerId, self.videoId)
                player = dict.get('player')
                if isinstance(player, str) and len(player) > 0:
                    self.videoData = dict
                    self.videoData['owner'] = self.userInfo
                    self.guiDelegate.videoDidUpdated_(args=[self.videoData])
            threading.Thread(target=updateVideo).start()
        return results
    
    # ObjCBridgeProtocol
    def release(self):
        pass
