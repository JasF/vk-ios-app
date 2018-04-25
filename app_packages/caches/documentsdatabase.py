from .basedatabase import BaseDatabase

class DocumentsDatabase(BaseDatabase):
    @staticmethod
    def filename():
        return 'documents'
    
    def params(self):
        return {'owner_id': 'integer', 'title': 'text', 'size': 'integer', 'ext': 'text', 'url': 'text', 'date': 'integer', 'type': 'integer', 'preview': 'text'}
    
    def objects(self):
        return ['preview']



