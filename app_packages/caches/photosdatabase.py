from .basedatabase import BaseDatabase

class PhotosDatabase(BaseDatabase):
    @staticmethod
    def filename():
        return 'photos'
    
    def params(self):
        return {'album_id': 'integer', 'owner_id': 'integer', 'photo_75': 'text', 'photo_130': 'text', 'photo_604': 'text', 'photo_807': 'text', 'photo_1280': 'text', 'photo_2560': 'text', 'width': 'integer', 'height': 'integer', 'text': 'text', 'date': 'integer', 'likes': 'text', 'reposts': 'text', 'comments': 'text', 'can_comment': 'integer', 'tags': 'text', 'access_key': 'text'}

    def objects(self):
        return ['likes', 'reposts', 'comments', 'tags']

    def getAll(self, ownerId, albumId):
        script = 'SELECT * FROM ' + self.tableName + ' WHERE owner_id = ' + str(ownerId)  + ' AND album_id = ' + str(albumId) + ' ORDER BY date ASC'
        result = []
        try:
            self.cursor.execute(script)
            result = self.cursor.fetchall()
        except Exception as e:
            print('getAll from base exception: ' + str(e))
        return result

    def getPhoto(self, ownerId, photoId):
        script = 'SELECT * FROM ' + self.tableName + ' WHERE owner_id = ' + str(ownerId)  + ' and id = ' + str(photoId)
        result = None
        try:
            self.cursor.execute(script)
            result = self.cursor.fetchone()
        except Exception as e:
            print('getPhoto from base exception: ' + str(e))
        return result
