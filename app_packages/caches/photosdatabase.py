from .basedatabase import BaseDatabase

class PhotosDatabase(BaseDatabase):
    @staticmethod
    def filename():
        return 'photos'
    
    def params(self):
        return {'album_id': 'integer', 'owner_id': 'integer', 'photo_75': 'text', 'photo_130': 'text', 'photo_604': 'text', 'photo_807': 'text', 'photo_1280': 'text', 'photo_2560': 'text', 'width': 'integer', 'height': 'integer', 'text': 'text', 'date': 'integer', 'likes': 'text', 'reposts': 'text', 'comments': 'text', 'can_comment': 'integer', 'tags': 'text', 'access_key': 'text'}

    def objects(self):
        return ['likes', 'reposts', 'comments', 'tags']
