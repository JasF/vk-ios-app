from .basedatabase import BaseDatabase

class VideosDatabase(BaseDatabase):
    @staticmethod
    def filename():
        return 'videos'
    
    def params(self):
        return {'owner_id': 'integer', 'title': 'text', 'duration': 'integer', 'description': 'text', 'date': 'integer', 'comments': 'integer', 'views': 'integer', 'photo_130': 'text', 'photo_320': 'text', 'adding_date': 'integer', 'player': 'text', 'can_edit': 'integer', 'can_add': 'integer', 'privacy_view': 'text', 'privacy_comment': 'text', 'can_comment': 'integer', 'can_repost': 'integer', 'likes': 'text', 'reposts': 'text', 'repeat': 'integer', 'width': 'integer', 'height': 'integer', 'photo_800': 'text', 'first_frame_320': 'text', 'first_frame_160': 'text', 'first_frame_130': 'text', 'first_frame_800': 'text'}
    
    def objects(self):
        return ['privacy_view', 'privacy_comment', 'likes', 'reposts'];

    def getVideo(self, ownerId, videoId):
        script = 'SELECT * FROM ' + self.tableName + ' WHERE owner_id = ' + str(ownerId)  + ' and id = ' + str(videoId)
        result = None
        try:
            self.cursor.execute(script)
            result = self.cursor.fetchone()
        except Exception as e:
            print('getPhoto from base exception: ' + str(e))
        return result

    def getById(self, ownerId, postId):
        self.cursor.execute('SELECT * FROM ' + self.tableName + ' WHERE (owner_id = ' + str(ownerId) + ') AND (id = ' + str(postId) + ')')
        result = self.cursor.fetchone()
        return result
