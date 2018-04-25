import vk
import json
import traceback
from vk import users as users
from caches.postsdatabase import PostsDatabase

class AnswersService:
    def __init__(self, usersDecorator):
        self.usersDecorator = usersDecorator
        pass
    
    def getAnswers(self, offset, next_from):
        response = None
        usersData = None
        try:
            api = vk.api()
            if isinstance(next_from, str):
                response = api.notifications.get(start_from=next_from, count=5)
            else:
                response = api.notifications.get(count=5)
            next_from = response.get('next_from')
            print('next_from: ' + str(next_from))
            l = response["items"]
            usersData = self.usersDecorator.usersDataFromAnswers(l)
            print('\n\n\n$$$$$answer l is: ' + json.dumps(response) + '\n$$$$$\n\n\n')
            #usersData = self.usersDecorator.usersDataFromPosts(l)
        except Exception as e:
            print('getAnswers.get exception: ' + str(e))
        results = {'response':response, 'users':usersData}
        return results, next_from

