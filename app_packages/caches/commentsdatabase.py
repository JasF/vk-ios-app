from .basedatabase import BaseDatabase

class CommentsDatabase(BaseDatabase):
    @staticmethod
    def filename():
        return 'comments'
    
    def params(self):
        return {'from_id': 'integer', 'date': 'integer', 'text': 'text', 'reply_to_user': 'integer', 'reply_to_comment': 'integer'}
