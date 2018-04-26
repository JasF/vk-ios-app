from .basedatabase import BaseDatabase


class PostsDatabase(BaseDatabase):
    @staticmethod
    def filename():
        return 'posts'
    
    def params(self):
        return {'id': 'integer', 'from_id': 'integer', 'owner_id': 'integer', 'date': 'integer', 'post_type': 'text', 'text': 'text', 'can_delete': 'integer', 'can_pin': 'integer', 'attachments': 'text', 'post_source': 'text', 'comments': 'text', 'likes': 'text', 'reposts': 'text', 'views': 'text', 'copy_history': 'text', 'source_id': 'integer', 'post_id': 'integer', 'audio': 'text', 'geo': 'text'}

    def objects(self):
        return ['attachments', 'post_source', 'comments', 'likes', 'reposts', 'views', 'copy_history', 'audio', 'geo']

    def primaryKeyName(self):
        return 'uid'
    
    def primaryKeyType(self):
        return 'text'
    
    def update(self, l):
        def safeGet(d,k):
            return str(d.get(k) if d.get(k) else 0)
        for d in l:
            uid = safeGet(d,'date') + '_' + safeGet(d,'owner_id') + '_' + safeGet(d,'source_id') + '_' + safeGet(d,'post_id') + '_' + safeGet(d,'type')
            d['uid'] = uid
        return BaseDatabase.update(self, l)

    def getById(self, ownerId, postId):
        self.cursor.execute('SELECT * FROM ' + self.tableName + ' WHERE (owner_id = ' + str(ownerId) + ' OR source_id = ' + str(ownerId) + ') AND (id = ' + str(postId) + ' OR post_id = ' + str(postId) + ')')
        result = self.cursor.fetchone()
        return result
