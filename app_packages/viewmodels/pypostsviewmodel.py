from objc import managers
from services.wallservice import WallService
from objcbridge import BridgeBase, ObjCBridgeProtocol
import vk, json, analytics
from caches.postsdatabase import PostsDatabase
from caches.videosdatabase import VideosDatabase
import threading, traceback
from pymanagers.pydialogsmanager import PyDialogsManager
from constants import g_CommentsCount
from vk import users
from vk.exceptions import VkAPIError

class PyPostsViewModelDelegate(BridgeBase):
    pass

class PyPostsViewModel(ObjCBridgeProtocol):
    def __init__(self, wallPostService, detailPhotoService, detailVideoService, delegateId):
        self.wallPostService = wallPostService
        self.detailPhotoService = detailPhotoService
        self.detailVideoService = detailVideoService
        self.guiDelegate = PyPostsViewModelDelegate(delegateId)

    def likeObjectWithTypeownerIditemIdaccessKeylike(self, type, ownerId, itemId, accessKey, like):
        analytics.log('Posts_like')
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
        analytics.log('Posts_repost')
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
        analytics.log('Posts_title_node_tapped')
        managers.shared().screensManager().showWallViewController_push_(args=[ownerId, True])

    def tappedOnCellWithUserId(self, userId):
        analytics.log('Posts_tapped_on_cell_with_userid')
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
        analytics.log('Posts_send_comment')
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
        analytics.log('Posts_tapped_on_post')
        managers.shared().screensManager().showWallPostViewControllerWithOwnerId_postId_(args=[ownerId, postId])

    def tappedOnPhotoWithIndexwithPostIdownerId(self, photoIndex, postId, ownerId):
        analytics.log('Posts_tapped_on_photo_with_index')
        managers.shared().screensManager().showImagesViewerViewControllerWithOwnerId_postId_photoIndex_(args=[ownerId, postId, photoIndex])
    
    def tappedOnPhotoItemWithIndexwithPostIdownerId(self, photoIndex, postId, ownerId):
        analytics.log('Posts_tapped_on_photoitem_with_index')
        managers.shared().screensManager().showImagesViewerViewControllerWithOwnerId_postId_photoIndex_(args=[ownerId, -postId, photoIndex])
    
    def tappedOnVideoWithIdownerIdrepresentation(self, videoId, ownerId, representation):
        analytics.log('Posts_tapped_on_video')
        #print('representation: ' + json.dumps(representation, indent=4))
        try:
            cache = VideosDatabase()
            cache.update([representation])
            cache.close()
        except Exception as e:
            print('tappedOnVideoWithIdownerIdrepresentation exception: ' + str(e))
        managers.shared().screensManager().showDetailVideoViewControllerWithOwnerId_videoId_(args=[ownerId, videoId])

    def optionsTappedWithPostIdownerIdisNewsViewController(self, postId, ownerId, isNewsViewController):
        try:
            dialogsManager = PyDialogsManager()
            items = ['copy_url']
            #if ownerId != vk.userId():
            items.append('report')
            # если новостная лента, скрываем новости источника (опционально)
            if isNewsViewController == True:
                items.append('it_is_not_interesting')
                items.append('hide_source_news')
            
            index, cancelled = dialogsManager.showRowsDialogWithTitles(items)
            if cancelled:
                return
            if items[index] == 'copy_url':
                self.guiDelegate.copyUrl_(args=['https://vk.com/id' + str(ownerId)])
            elif items[index] == 'report':
                self.report('post', ownerId, postId)
            elif items[index] == 'it_is_not_interesting':
                self.guiDelegate.hideOptionsNode()
                self.ignoreItem('post', ownerId, postId)
            elif items[index] == 'hide_source_news':
                self.guiDelegate.hideOptionsNode()
                self.hideSource(ownerId)
        except Exception as e:
            print('optionsTappedWithPostIdownerId exception: ' + str(e))

    def ignoreItem(self, aType, ownerId, itemId):
        results = 0
        if aType == 'post':
            type = 'wall'
        elif aType == 'photo':
            type = 'photo'
        elif aType == 'video':
            type = 'video'
        else:
            raise ValueError('unknown type for ignoreItem: ' + str(aType))
        try:
            api = vk.api()
            results = api.newsfeed.ignoreItem(type=type, owner_id=ownerId, item_id=itemId)
            print('ignoreItem result: ' + str(results) + '; ownerId: ' + str(ownerId) + '; itemId: ' + str(itemId))
        except Exception as e:
            print('ignoreItem exception: ' + str(e))
        if not isinstance(results, int) or results != 1:
            dialogsManager = PyDialogsManager()
            dialogsManager.showDialogWithMessage('error_ignore_item')

    def hideSource(self, userId):
        results = 0
        try:
            api = vk.api()
            if userId > 0:
                results = api.newsfeed.addBan(user_ids=userId)
            elif userId < 0:
                results = api.newsfeed.addBan(group_ids=abs(userId))
            else:
                raise ValueError('userId on hideSource is 0')
        except Exception as e:
            print('hideSource exception: ' + str(e))
    
        if not isinstance(results, int) or results != 1:
            dialogsManager = PyDialogsManager()
            dialogsManager.showDialogWithMessage('error_ignore_item')
                
    def report(self, type, ownerId, itemId):
        response = False
        results = 0
        dialogsManager = PyDialogsManager()
        try:
            api = vk.api()
            if type == 'post':
                results = api.wall.reportPost(owner_id=ownerId, post_id=itemId)
            elif type == 'user':
                items = ['porn','spam','insult','advertisment']
                index, cancelled = dialogsManager.showRowsDialogWithTitles(items)
                if cancelled:
                    return
                type = items[index]
                message, cancelled = dialogsManager.showTextFieldDialogWithText('enter_report_message')
                if cancelled:
                    return
                results = api.users.report(user_id=ownerId, type=type, comment=message)
            elif type == 'photo':
                results = api.photos.report(owner_id=ownerId, photo_id=itemId)
            elif type == 'video':
                message, cancelled = dialogsManager.showTextFieldDialogWithText('enter_report_message')
                if cancelled:
                    return
                results = api.video.report(owner_id=ownerId, video_id=itemId, comment=message)
            elif type == 'post_comment':
                results = api.wall.reportComment(owner_id=ownerId, comment_id=itemId)
            elif type == 'photo_comment':
                results = api.photos.reportComment(owner_id=ownerId, comment_id=itemId)
            elif type == 'video_comment':
                results = api.video.reportComment(owner_id=ownerId, comment_id=itemId)
            else:
                raise ValueError('unsupported type of item for report')
            if isinstance(results, int) and results == 1:
                response = True
        
        except Exception as e:
            print('posts report exception: ' + str(e))

        if response == False:
            print('report send failed with results: ' + str(results))
            dialogsManager.showDialogWithMessage('error_reporting')
        else:
            dialogsManager.showDialogWithMessage('report_sended_successfully')
            print('report sended successfully for type: ' + str(type))
        pass

    def tappedOnCommentWithOwnerIdcommentIdtypeparentItemOwnerId(self, ownerId, commentId, type, parentItemOwnerId):
        try:
            items = []
            dialogsManager = PyDialogsManager()
            items.append('report')
            if parentItemOwnerId == vk.userId():
                items.append('comment_delete')
            index, cancelled = dialogsManager.showRowsDialogWithTitles(items)
            if cancelled:
                return
            if index == 0:
                self.report(type, ownerId, commentId)
            elif index == 1:
                self.deleteComment(type, ownerId, commentId, parentItemOwnerId)
        except Exception as e:
            print('tappedOnCommentWithOwnerIdcommentId exception: ' + str(e))

    def deleteComment(self, type, ownerId, commentId, parentItemOwnerId):
        results = 0
        try:
            api = vk.api()
            if type == 'post_comment':
                results = api.wall.deleteComment(owner_id=parentItemOwnerId, comment_id=commentId)
            elif type == 'photo_comment':
                results = api.photos.deleteComment(owner_id=parentItemOwnerId, comment_id=commentId)
            elif type == 'video_comment':
                results = api.video.deleteComment(owner_id=parentItemOwnerId, comment_id=commentId)
        except Exception as e:
            print('deleteComment exception: ' + str(e))
        if not isinstance(results, int) or results != 1:
            dialogsManager = PyDialogsManager()
            dialogsManager.showDialogWithMessage('error_delete_comment')
        else:
            self.guiDelegate.commentDeleted()

    def optionsTappedWithPhotoIdownerId(self, photoId, ownerId):
        try:
            dialogsManager = PyDialogsManager()
            items = []
            items.append('report')
            index, cancelled = dialogsManager.showRowsDialogWithTitles(items)
            if cancelled:
                return
            self.report('photo', ownerId, photoId)
        except Exception as e:
            print('optionsTappedWithPhotoId exception: ' + str(e))

    def optionsTappedWithVideoIdownerId(self, videoId, ownerId):
        try:
            dialogsManager = PyDialogsManager()
            items = []
            items.append('report')
            index, cancelled = dialogsManager.showRowsDialogWithTitles(items)
            if cancelled:
                return
            self.report('video', ownerId, videoId)
        except Exception as e:
            print('optionsTappedWithVideoIdownerId exception: ' + str(e))


    def optionsTappedWithUserId(self, userId):
        try:
            dialogsManager = PyDialogsManager()
            items = []
            if userId > 0:
                items.append('report')
            items.append('block_user')
            index, cancelled = dialogsManager.showRowsDialogWithTitles(items)
            if cancelled:
                return
            if index == 0 and userId > 0:
                self.report('user', userId, 0)
            else:
                userData = users.getShortUserById(userId)
                first_name = userData.get('first_name')
                last_name = userData.get('last_name')
                if userId < 0:
                    first_name = userData.get('name')
                userName = ""
                if not isinstance(first_name, str) and not isinstance(last_name, str):
                    print('name not defined for userData: ' + json.dumps(userData, indent=4))
                    return
                elif isinstance(first_name, str) and isinstance(last_name, str):
                    userName = first_name + ' ' + last_name
                elif isinstance(first_name, str):
                    userName = first_name
                else:
                    userName = last_name
                locString = self.guiDelegate.localize_(args=['are_you_sure_for_block_username'], withResult=True) + userName + '?'
                index, cancelled = dialogsManager.showYesNoDialogWithMessage(locString, "ban_user_button", "cancel")
                if cancelled == True:
                    return
                self.blockUser(userId)
        except Exception as e:
            print('optionsTappedWithUserId exception: ' + str(e))
            print(traceback.format_exc())

    def blockUser(self, userId):
        result = 0
        try:
            api = vk.api()
            result = api.account.ban(owner_id=userId)
        except VkAPIError as e:
            if 'already blacklisted' in e.message:
                result = 2
        except Exception as e:
            print('blockUser exception: ' + str(e))
        message = ""
        if isinstance(result, int) and result == 2:
            message = 'already_blacklisted'
        elif not isinstance(result, int) or result != 1:
            message = 'error_ban_user' if userId>0 else 'error_ban_group'
        else:
            message = 'user_successfully_banned' if userId>0 else 'group_successfully_banned'

        dialogsManager = PyDialogsManager()
        dialogsManager.showDialogWithMessage(message)

    # ObjCBridgeProtocol
    def release(self):
        pass
