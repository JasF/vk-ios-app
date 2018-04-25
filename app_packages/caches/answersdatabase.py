from .basedatabase import BaseDatabase

class PhotosDatabase(BaseDatabase):
    @staticmethod
    def filename():
        return 'photos'
    
    def params(self):
        return {'type': 'text', 'date': 'integer', 'parent': 'text', 'feedback': 'text'}
    
    def objects(self):
        return ['parent', 'feedback']
    '''
    def getAll(self, ownerId, albumId):
        script = 'SELECT * FROM ' + self.tableName + ' WHERE owner_id = ' + str(ownerId)  + ' AND album_id = ' + str(albumId) + ' ORDER BY date ASC'
        result = []
        try:
            self.cursor.execute(script)
            result = self.cursor.fetchall()
        except Exception as e:
            print('getAll from base exception: ' + str(e))
        return result
        '''
