from .basedatabase import BaseDatabase

class UsersDatabase(BaseDatabase):
    @staticmethod
    def filename():
        return 'users'
    
    def params(self):
        return {'first_name': 'text', 'last_name': 'text', 'photo_50': 'text', 'photo_100': 'text', 'photo_200_orig': 'text', 'photo_200': 'text', 'photo_400_orig': 'text', 'photo_max': 'text', 'photo_max_orig': 'text', 'name': 'text', 'screen_name': 'text', 'is_closed': 'integer', 'type': 'text', 'hidden': 'integer'}
    
    def getShortUsersByIds(self, ids):
        return self.selectIdsByKeys(ids, ['id','first_name','last_name','photo_50','photo_100','photo_200','name'])
