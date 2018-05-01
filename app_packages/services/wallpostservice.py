import vk, os, sys
import json
from vk import users
import traceback
from vk import users as users
from caches.postsdatabase import PostsDatabase
from caches.commentsdatabase import CommentsDatabase

class WallPostService:
    def __init__(self, usersDecorator, commentsService):
        self.usersDecorator = usersDecorator
        self.commentsService = commentsService
        pass

    def getPostById(self, ownerId, postId):
        response = None
        usersData = None
        l = None
        try:
            cache = PostsDatabase()
            result = cache.getById(ownerId, postId)
            cache.close()
            if not result:
                return None
            l = [result]
            usersData = self.usersDecorator.usersDataFromPosts(l)
        
        except Exception as e:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
            print(exc_type, fname, exc_tb.tb_lineno)
            print('wall post service exception: ' + str(e))
            print(traceback.format_exc())
        results = {'response':{'items':l}, 'users':usersData}
        return results
        
        return result

    def getComments(self, ownerId, postId, offset, count):
        result = self.commentsService.getWallComments(ownerId, postId, offset, count)
        return result

    def sendComment(self, ownerId, postId, messsage, reply_to_comment=0):
        api = vk.api()
        result = None
        try:
            result = api.wall.createComment(owner_id=ownerId, post_id=postId, text=messsage, reply_to_comment=reply_to_comment)
        except Exception as e:
            print('wallService: sendComments exception: ' + str(e))
        return result
