from .basedatabase import BaseDatabase

class MessagesDatabase(BaseDatabase):
    @staticmethod
    def filename():
        return 'messages'
    
    def params(self):
        return {'body': 'text', 'user_id': 'integer', 'from_id': 'integer', 'date': 'integer', 'read_state': 'integer', 'out': 'integer'}

    def getFromMessageId(self, user_id, startMessageId, batchSize):
        script = 'SELECT * FROM messages WHERE user_id = ' + str(user_id) + ' AND id <= ' + str(startMessageId) + ' ORDER BY id DESC LIMIT ' + str(batchSize) + ';'
        self.cursor.execute(script)
        results = self.cursor.fetchall()
        return results

    def getLatest(self, user_id, batchSize):
        script = 'SELECT * FROM messages WHERE user_id = ' + str(user_id) + ' ORDER BY id DESC LIMIT ' + str(batchSize) + ';'
        self.cursor.execute(script)
        results = self.cursor.fetchall()
        return results

    def messageWithId(self, messageId):
        script = 'SELECT * FROM messages WHERE id = ' + str(messageId) + ';'
        self.cursor.execute(script)
        result = self.cursor.fetchone()
        return result
