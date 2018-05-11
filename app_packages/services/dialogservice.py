import vk, json
from caches.messagesdatabase import MessagesDatabase
from services.usersdecorator import UsersDecorator
from postproc import textpatcher

def updateMessagesResponseWithUsers(response):
    try:
        l = response['items']
        #print('updateMessagesResponseWithUsers content: ' + json.dumps(l, indent=4))
        for d in l:
            atts = d.get('attachments')
            if not isinstance(atts, list):
                continue
            for att in atts:
                try:
                    if not isinstance(att, dict):
                        continue
                    if att['type'] == 'wall':
                        print('\n\n\nWALL: \n\n\n' + json.dumps(att, indent=4))
                        walldict = att['wall']
                        textpatcher.cropTagsOnPostsResults({'items':[walldict]})
                        ud = UsersDecorator()
                        usersData = ud.usersDataFromPosts([walldict])
                        print('USERS_DATA_FROM_POSTS: ' + json.dumps(usersData, indent=4))
                        usersDict = {}
                        for ud in usersData:
                            id = ud.get('id')
                            if isinstance(id, int):
                                usersDict[id] = ud
                        id = walldict.get('from_id')
                        if isinstance(id, int):
                            userdict = usersDict.get(id)
                            if isinstance(userdict, dict):
                                walldict['user'] = userdict
                            else:
                                id = walldict.get('to_id')
                                if isinstance(id, int):
                                    userdict = usersDict.get(id)
                                    if isinstance(userdict, dict):
                                        walldict['user'] = userdict

                        copy_history = walldict.get('copy_history')
                        if isinstance(copy_history, list):
                            for h in copy_history:
                                id = h.get('owner_id')
                                if isinstance(id, int):
                                    userdict = usersDict.get(id)
                                    if isinstance(userdict, dict):
                                        h['user'] = userdict
                                    else:
                                        id = usersDict.get('from_id')
                                        if isinstance(id, int):
                                            userdict = usersDict.get(id)
                                            if isinstance(userdict, dict):
                                                h['user'] = userdict

                        print('usersData is: ' + json.dumps(usersData, indent=4))
                        #walldict['users_data'] = usersData
                except Exception as e:
                    print('updateMessagesResponseWithUsers deep exception: ' + str(e))
                    pass
    except Exception as e:
        print('updateMessagesResponseWithUsers exception: ' + str(e))

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
            updateMessagesResponseWithUsers(response)
            l = response["items"]
            messages.update(l)
            messages.close()
    
            print('messages history: ' + json.dumps(response, indent=4))
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
        #print('offset: ' + str(offset) + '; userId: ' + str(userId) + '; startMessageId: ' + str(startMessageId))
        response = None
        usersData = None
        try:
            messages = MessagesDatabase()
            localcache = messages.getFromMessageId(userId, startMessageId, self.batchSize)
            if len(localcache) > 1:
                print('fetched ' + str(len(localcache)) + ' messages startMessageId: ' + str(startMessageId) + ' from cache. Network request skipping.')
                return {'response':{'items':localcache}}
            
            
            response = self.api.messages.getHistory(user_id=userId, offset=offset, count=20, start_message_id=startMessageId)
            updateMessagesResponseWithUsers(response)
            l = response["items"]
            messages.update(l)
            messages.close()
        except Exception as e:
            print('get messages exception: ' + str(e))
        return {'response':response, 'users':usersData}
    
    def sendTextMessageuserId(self, text, userId, random_id):
        self.initializeIfNeeded()
        #self.api.captcha.force()
        return self.api.messages.send(user_id=userId, peer_id=userId, message=text, random_id=random_id)

