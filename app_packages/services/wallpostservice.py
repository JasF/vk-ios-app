import vk
import json
from vk import users
import traceback
from vk import users as users

class WallPostService:
    def __init__(self, parameters):
        self.userInfo = None
        print('WallService parameters: ' + str(parameters))
        self.userId = parameters.get('userId')
        if self.userId == None or self.userId == 0:
            self.userId = vk.userId()

