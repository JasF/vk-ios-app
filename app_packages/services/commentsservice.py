import vk, os, sys
import json
from vk import users
import traceback
from vk import users as users
from caches.postsdatabase import PostsDatabase
from caches.commentsdatabase import CommentsDatabase

class CommentsService():
    def getWallComments(self, ownerId, postId, offset, count):
        result = {}
        try:
            api = vk.api()
            result = api.wall.getComments(owner_id=ownerId, post_id=postId, offset=offset, count=count, extended=1)
            result = self.processResult(result)
            l = result['items']
            cache = CommentsDatabase()
            cache.update(l)
            cache.close()
        except Exception as e:
            print('getWallComments exception: ' + str(e))
            print(traceback.format_exc())
        return result

    def getPhotoComments(self, ownerId, photoId, offset, count):
        result = {}
        try:
            api = vk.api()
            result = api.photos.getComments(owner_id=ownerId, photo_id=photoId, offset=offset, count=count, extended=1)
            result = self.processResult(result)
            l = result['items']
            '''
            cache = CommentsDatabase()
            cache.update(l)
            cache.close()
            '''
        except Exception as e:
            print('getPhotoComments: get comments exception: ' + str(e))
        return result

    def getVideoComments(self, ownerId, videoId, offset, count):
        api = vk.api()
        result = None
        try:
            result = api.video.getComments(owner_id=ownerId, video_id=videoId, offset=offset, count=count, extended=1)
            result = self.processResult(result)
            l = result['items']
            myString.find('s')
            '''
                cache = CommentsDatabase()
                cache.update(l)
                cache.close()
                '''
        except Exception as e:
            print('getVideoComments: get comments exception: ' + str(e))
        return result
    
    def doCropTags(self, text):
        first = text.find('[')
        second = text.find('|')
        third = text.find(']')
        if first < 0 or second < 0 or third < 0:
            return text, False
        if text.find(' ', first, second) >= 0:
            return text, False
        name = text[second+1:third]
        pathed = text[:first] + name + text[third+1:]
        return pathed, True
            
    def cropTags(self, text):
        result = text
        while True:
            result, success = self.doCropTags(result)
            if not success:
                break
        return result

    def processResult(self, result):
        comments = result['items']
        print('processResult: ' + json.dumps(comments, indent=4))
        for comment in comments:
            comment['text'] = self.cropTags(comment['text'])
        return result

