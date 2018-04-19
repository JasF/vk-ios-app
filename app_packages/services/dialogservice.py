import vk
import json
from vk import users as users
from caches.messages import MessagesDatabase

class DialogService:
    def __init__(self):
        self.api = None
    
    def initializeIfNeeded(self):
        if not self.api:
            self.api = vk.api()
    
    def getMessagesuserId(self, offset, userId):
        self.initializeIfNeeded()
        print('offset: ' + str(offset) + '; userId: ' + str(userId))
        response = None
        usersData = None
        try:
            messages = MessagesDatabase()
            localcache = messages.getLatest(userId)
            
            response = self.api.messages.getHistory(user_id=userId, offset=offset, count=20)
            l = response["items"]
            messages.update(l)
            messages.close()
        except Exception as e:
            print('get messages exception: ' + str(e))
        return {'response':response, 'users':usersData}


    def getMessagesuserIdstartMessageId(self, offset, userId, startMessageId):
        self.initializeIfNeeded()
        print('offset: ' + str(offset) + '; userId: ' + str(userId) + '; startMessageId: ' + str(startMessageId))
        response = None
        usersData = None
        try:
            messages = MessagesDatabase()
            
            
            response = self.api.messages.getHistory(user_id=userId, offset=offset, count=20, start_message_id=startMessageId)
            l = response["items"]
            messages.update(l)
            messages.close()
        except Exception as e:
            print('get messages exception: ' + str(e))
        return {'response':response, 'users':usersData}

    def sendTextMessageuserId(self, text, userId):
        self.initializeIfNeeded()
        print('sending text:' + str(text) + '; userId: ' + str(userId))
        self.api.messages.send(user_id=userId, peer_id=userId, message=text)
