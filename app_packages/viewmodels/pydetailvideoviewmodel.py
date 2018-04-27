from objc import managers
from services.wallservice import WallService
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk, json

# https://vk.com/dev/wall.getComments
class PyDetailVideoViewModel():
    def __init__(self, detailVideoService, ownerId, videoId):
        self.detailVideoService = detailVideoService
        self.ownerId = ownerId
        self.videoId = videoId
        print('PyDetailVideoViewModel ownerId: ' + str(ownerId) + '; videoId: ' + str(videoId))
        self.videoData = None
    
    # protocol methods implementation
    def getVideoData(self, offset):
        results = {}
        if not self.videoData:
            self.videoData = self.detailVideoService.getVideo(self.ownerId, self.videoId)
            comments = self.detailVideoService.getComments(self.ownerId, self.videoId, offset)
            results['comments'] = comments
        if offset == 0:
            results['videoData'] = self.videoData
        return results
    
    # ObjCBridgeProtocol
    def release(self):
        pass