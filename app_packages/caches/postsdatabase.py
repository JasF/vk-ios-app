from .basedatabase import BaseDatabase


class PostsDatabase(BaseDatabase):
    def __init__(self):
        self.cache = {}
    @staticmethod
    def filename():
        return 'posts'
    
    def params(self):
        return {'text': 'text'}
