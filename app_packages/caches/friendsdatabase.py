from .basedatabase import BaseDatabase

class FriendsDatabase(BaseDatabase):
    def __init__(self):
        super().__init__()
        print('tablse friends created')
    
    @staticmethod
    def filename():
        return 'friends'
    
    def params(self):
        return {'position': 'integer'}

    def friendsCount(self):
        counter = 0;
        try:
            self.cursor.execute('SELECT * FROM ' + self.tableName  + ' ORDER BY position DESC LIMIT 1')
            upperFriend = self.cursor.fetchone()
            #if len(upperFriend) > 0:
            if upperFriend:
                counter = upperFriend.get('position')
        except Exception as e:
            print('fetch count exception: ' + str(e))
        finally:
            print('appendFriendsIds count is: ' + str(counter))
        return counter
            
    def getFriendsIds(self, userId, offset, count):
        result = []
        try:
            script = 'SELECT * FROM ' + self.tableName + ' WHERE id = ' + str(userId) + ' ORDER BY position ASC LIMIT ' + str(count) + ' OFFSET ' + str(offset)
            self.cursor.execute(script)
            result = self.cursor.fetchall()
        except Exception as e:
            print('getFriendsIds ex: ' + str(e))
        return result

    def appendFriendsIds(self, ids):
        counter = self.friendsCount() + 1
        friendsArray = []
        for id in ids:
            friendsArray.append({'id': id, 'position': counter})
            counter += 1

        self.update(friendsArray)
        pass

