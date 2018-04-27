from .basedatabase import BaseDatabase

class PhotosDatabase(BaseDatabase):
    @staticmethod
    def filename():
        return 'answers'
    
    def params(self):
        return {'type': 'text', 'date': 'integer', 'parent': 'text', 'feedback': 'text'}
    
    def objects(self):
        return ['parent', 'feedback']