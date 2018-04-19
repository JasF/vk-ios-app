from .basedatabase import BaseDatabase

class MessagesDatabase(BaseDatabase):
    @staticmethod
    def filename():
        return 'messages'
    
    def params(self):
        return {'body': 'text', 'user_id': 'integer', 'from_id': 'integer', 'date': 'integer', 'read_state': 'integer', 'out': 'integer'}

    def getLatest(self, user_id):
        script = 'SELECT * FROM messages WHERE user_id = ' + str(user_id) + ' ORDER BY id DESC LIMIT 2 OFFSET 2;'
            #'SELECT * FROM messages WHERE user_id = ' + str(user_id) + ' ORDER BY user_id ASC LIMIT 2'
        print('getLatest script is: ' + str(script))
        self.cursor.execute(script)
        results = self.cursor.fetchall()
        print('results is: ' + str(results))
        '''
            def selectIds(self, ids, keys):
            script = 'SELECT ' + keys + ' FROM ' + self.tableName + ' WHERE id IN (' + ','.join(str(id) for id in ids) + ')'
            self.cursor.execute(script)
            result = self.cursor.fetchall()
            return result
        '''
