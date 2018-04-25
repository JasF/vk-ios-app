import vk
import json
import traceback
from vk import users as users
from caches.documentsdatabase import DocumentsDatabase

class DocumentsService:
    def __init__(self):
        pass
    
    def getDocuments(self, ownerId, offset):
        api = vk.api()
        response = None
        count = 0
        try:
            response = api.docs.get(owner_id=ownerId, offset=offset)
            l = response['items']
            count = len(l)
            '''
            cache = DocumentsDatabase()
            cache.update(l)
            cache.close()
            '''
        except Exception as e:
            print('getDocuments exception: ' + str(e))
        return {'response': response}, count

