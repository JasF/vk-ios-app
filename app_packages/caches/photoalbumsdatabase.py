from .basedatabase import BaseDatabase

class PhotoAlbumsDatabase(BaseDatabase):
    @staticmethod
    def filename():
        return 'photoalbums'
    
    def params(self):
        return {'thumb_id': 'integer', 'owner_id': 'integer', 'title': 'text', 'size': 'integer', 'thumb_src': 'text'}
