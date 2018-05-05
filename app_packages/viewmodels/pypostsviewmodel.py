from objc import managers
from services.wallservice import WallService
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk, json
from caches.postsdatabase import PostsDatabase
from caches.videosdatabase import VideosDatabase
import threading
from pymanagers.pydialogsmanager import PyDialogsManager
from constants import g_CommentsCount
from vk import users

class PyPostsViewModel(ObjCBridgeProtocol):
    def __init__(self, wallPostService, detailPhotoService, detailVideoService):
        self.wallPostService = wallPostService
        self.detailPhotoService = detailPhotoService
        self.detailVideoService = detailVideoService

    def likeObjectWithTypeownerIditemIdaccessKeylike(self, type, ownerId, itemId, accessKey, like):
        try:
            if type == 'wall':
                type = 'post'
            
            api = vk.api()
            #print('type: ' + str(type) + ' ownerId ' + str(ownerId) + ' itemId ' + str(itemId) + ' accessKey ' + str(accessKey) + ' like ' + str(like))
            if like == True:
                response = api.likes.add(type=type, owner_id=ownerId, item_id=itemId, access_key=accessKey)
            else:
                response = api.likes.delete(type=type, owner_id=ownerId, item_id=itemId)
            
            def updateCache():
                likesCount = response.get('likes')
                if isinstance(likesCount, int):
                    if type == 'wall':
                        cache = PostsDatabase()
                        data = cache.getById(ownerId, itemId)
                        likes = data['likes']
                        likes['count'] = likesCount
                        likes['user_likes'] = 1 if like == True else 0
                        data['likes'] = likes
                        cache.update([data])
                        cache.close()
                    elif type == 'video':
                        cache = VideosDatabase()
                        data = cache.getById(ownerId, itemId)
                        print('video data: ' + json.dumps(data, indent=4))
                        likes = data['likes']
                        likes['count'] = likesCount
                        likes['user_likes'] = 1 if like == True else 0
                        data['likes'] = likes
                        cache.update([data])
                        cache.close()
                        
            thread = threading.Thread(target=updateCache)
            thread.start()
                
        except Exception as e:
            print('likeObjectWithTypeownerIditemIdaccessKeylike exception: ' + str(e))
        return response
    
    def doRepostForFriends(self, identifier, message):
        if not isinstance(message, str):
            message = ''
        try:
            api = vk.api()
            response = api.wall.repost(object=identifier, message=message)
            print('doRepostForFriends response: ' + json.dumps(response))
            '''
            def updateCache():
                likesCount = response.get('likes')
                if isinstance(likesCount, int):
                    cache = PostsDatabase()
                    data = cache.getById(ownerId, itemId)
                    likes = data['likes']
                    likes['count'] = likesCount
                    likes['user_likes'] = 1 if like == True else 0
                    data['likes'] = likes
                    cache.update([data])
                    cache.close()
            thread = threading.Thread(target=updateCache)
            thread.start()
    
                '''
        except Exception as e:
            print('doRepostForFriends exception: ' + str(e))
        return response
    
    def repostObjectWithIdentifier(self, identifier):
        dialogsManager = PyDialogsManager()
        index, cancelled = dialogsManager.showRowsDialogWithTitles(['repost_for_friends'])
        if cancelled:
            return {}
        if index == 0:
            text, cancelled = dialogsManager.showTextFieldDialogWithText('repost_enter_message')
            if cancelled:
                return {}
            return self.doRepostForFriends(identifier, text)
        return {}
    
    def titleNodeTapped(self, ownerId):
        managers.shared().screensManager().showWallViewController_push_(args=[ownerId, True])

    def tappedOnCellWithUserId(self, userId):
        managers.shared().screensManager().showWallViewController_push_(args=[userId, True])

    def preloadCommentsWithTypeownerIdpostIdcountloaded(self, type, ownerId, postId, count, loaded):
        loadCount = count-loaded
        if loadCount < 0:
            return {}
        loadCount = min(loadCount, g_CommentsCount)
        offset = count - (loaded + loadCount)
        comments = []
        try:
            if type == 'wall':
                comments = self.wallPostService.getComments(ownerId, postId, offset, loadCount)
            elif type == 'photo':
                comments = self.detailPhotoService.getComments(ownerId, postId, offset, loadCount)
            elif type == 'video':
                comments = self.detailVideoService.getComments(ownerId, postId, offset, loadCount)
        except Exception as e:
            print('preloadCommentsWithTypeownerIdpostIdcountloaded exception: ' + str(e))
        #print( 'commens common preload ' + str(type) + ' ' + str(ownerId) + ' ' + str(postId) + ' ' + str(count) + ' ' + str(loaded) + ' loading: ' + str(loadCount) + ' offset: ' + str(offset))
        return comments

    def sendCommentWithTypeownerIdpostIdtext(self, type, ownerId, postId, text):
        response = {}
        try:
            if type == 'wall':
                response = self.wallPostService.sendComment(ownerId, postId, text, 0)
            elif type == 'photo':
                response = self.detailPhotoService.sendComment(ownerId, postId, text, 0)
            elif type == 'video':
                response = self.detailVideoService.sendComment(ownerId, postId, text, 0)
        except Exception as e:
            print('preloadCommentsWithTypeownerIdpostIdcountloaded exception: ' + str(e))
        commentId = 0
        if isinstance(response, int):
            response = {'comment_id': response}
        try:
            commentId = response['comment_id']
        except:
            pass
        if commentId == 0:
            dialogsManager = PyDialogsManager()
            dialogsManager.showDialogWithMessage('error_send_comment')
        else:
            try:
                response['user_info'] = users.getShortUserById(vk.userId())
            except:
                pass
        return response
    
    def tappedOnPostWithOwnerIdpostId(self, ownerId, postId):
        managers.shared().screensManager().showWallPostViewControllerWithOwnerId_postId_(args=[ownerId, postId])

    def tappedOnPhotoWithIndexwithPostIdownerId(self, photoIndex, postId, ownerId):
        managers.shared().screensManager().showImagesViewerViewControllerWithOwnerId_postId_photoIndex_(args=[ownerId, postId, photoIndex])
    
    def tappedOnVideoWithIdownerIdrepresentation(self, videoId, ownerId, representation):
        print('representation: ' + json.dumps(representation, indent=4))
        try:
            cache = VideosDatabase()
            cache.update([representation])
            cache.close()
        except Exception as e:
            print('tappedOnVideoWithIdownerIdrepresentation exception: ' + str(e))
        managers.shared().screensManager().showDetailVideoViewControllerWithOwnerId_videoId_(args=[ownerId, videoId])
    
    # ObjCBridgeProtocol
    def release(self):
        pass
