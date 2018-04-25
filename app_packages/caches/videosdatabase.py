from .basedatabase import BaseDatabase

class VideosDatabase(BaseDatabase):
    @staticmethod
    def filename():
        return 'videos'
    
    def params(self):
        return {'owner_id': 'integer', 'title': 'text', 'duration': 'integer', 'description': 'text', 'date': 'integer', 'comments': 'integer', 'views': 'integer', 'width': 'integer', 'height': 'integer', 'photo_130': 'text', 'photo_320': 'text', 'photo_800': 'text', 'adding_date': 'integer', 'first_frame_320': 'text', 'first_frame_160': 'text', 'first_frame_130': 'text', 'first_frame_800': 'text', 'player': 'text', 'can_add': 'integer'}


