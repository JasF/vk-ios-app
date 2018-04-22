import vk
import json
from caches.messagesdatabase import MessagesDatabase

class DialogService:
    def __init__(self):
        self.batchSize = 20
        self.api = None
    
    def initializeIfNeeded(self):
        if not self.api:
            self.api = vk.api()
    
    def getMessagesuserId(self, offset, userId):
        self.initializeIfNeeded()
        response = None
        usersData = None
        try:
            messages = MessagesDatabase()
            localcache = messages.getLatest(userId, self.batchSize)
            if len(localcache):
                print('fetched ' + str(len(localcache)) + ' messages from cache. Network request skipping.')
                return {'response':{'items':localcache}}
            
            response = self.api.messages.getHistory(user_id=userId, offset=offset, count=self.batchSize)
            l = response["items"]
            messages.update(l)
            messages.close()
        except Exception as e:
            print('get messages exception: ' + str(e))
        return {'response':response, 'users':usersData}

    def markAsRead(self, peerId, messageId):
        self.initializeIfNeeded()
        try:
            response = self.api.messages.markAsRead(peer_id=peerId, message_ids=messageId)
        except Exception as e:
            print('markAsRead exception: ' + str(e))
        return response
    
    def sendTyping(self, userId):
        try:
            response = self.api.messages.setActivity(user_id=userId, type='typing')
        except Exception as e:
            print('sendTyping exception: ' + str(e))
        return response
            
    def getMessagesuserIdstartMessageId(self, offset, userId, startMessageId):
        self.initializeIfNeeded()
        print('offset: ' + str(offset) + '; userId: ' + str(userId) + '; startMessageId: ' + str(startMessageId))
        response = None
        usersData = None
        try:
            messages = MessagesDatabase()
            localcache = messages.getFromMessageId(userId, startMessageId, self.batchSize)
            if len(localcache) > 1:
                print('fetched ' + str(len(localcache)) + ' messages startMessageId: ' + str(startMessageId) + ' from cache. Network request skipping.')
                return {'response':{'items':localcache}}
            
            
            response = self.api.messages.getHistory(user_id=userId, offset=offset, count=20, start_message_id=startMessageId)
            l = response["items"]
            messages.update(l)
            messages.close()
        except Exception as e:
            print('get messages exception: ' + str(e))
        return {'response':response, 'users':usersData}
    
    def sendTextMessageuserId(self, text, userId):
        self.initializeIfNeeded()
        return self.api.messages.send(user_id=userId, peer_id=userId, message=text)
