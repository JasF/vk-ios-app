from .basedatabase import BaseDatabase


class PostsDatabase(BaseDatabase):
    @staticmethod
    def filename():
        return 'posts'
    
    def params(self):
        return {'from_id': 'integer', 'owner_id': 'integer', 'date': 'integer', 'post_type': 'text', 'text': 'text', 'can_delete': 'integer', 'can_pin': 'integer', 'attachments': 'text', 'post_source': 'text', 'comments': 'text', 'likes': 'text', 'reposts': 'text', 'views': 'text', 'copy_history': 'text', 'source_id': 'integer', 'post_id': 'integer', 'audio': 'text'}

    def objects(self):
        return ['attachments', 'post_source', 'comments', 'likes', 'reposts', 'views', 'copy_history', 'audio']

