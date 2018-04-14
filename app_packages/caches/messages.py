from .basedatabase import BaseDatabase

class MessagesDatabase(BaseDatabase):
    def __init__(self):
        super(MessagesDatabase, self).__init__('messages')
    
    def params(self):
        return {'body': 'text', 'user_id': 'integer', 'from_id': 'integer', 'date': 'integer', 'read_state': 'integer', 'out': 'integer'}
    '''
    def getShortUsersByIds(self, ids):
        return self.selectIds(ids, '*')
       '''
