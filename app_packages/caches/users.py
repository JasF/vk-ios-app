import os, sys, sqlite3

class UsersDatabase():
    def __init__(self):
        self.initialize()

    def close(self):
        if self.conn:
            self.conn.close()
    
    def initialize(self):
        self.conn = None
        path = sys.argv[1] + '/databases'
        os.makedirs(path, exist_ok=True)
        path += '/users.sql'
        try:
            self.conn = sqlite3.connect(path)
            self.conn.row_factory = lambda c, r: dict([(col[0], r[idx]) for idx, col in enumerate(c.description)])
            self.cursor = self.conn.cursor()
            self.cursor.execute('CREATE TABLE IF NOT EXISTS users (id integer PRIMARY KEY, first_name text, last_name text, photo_50 text, photo_100 text, photo_200_orig text, photo_200 text, photo_400_orig text, photo_max text, photo_max_orig text, name text, screen_name text, is_closed integer, type text)')
        except Exception as e:
            print('connect to database ' + path + ' error: ' + str(e))
            return
        print('Database users opened!')

    def update(self, usersList):
        try:
            script = ''
            def vtostr(v):
                if isinstance(v, str):
                    return "'" + v + "'"
                elif isinstance(v, int):
                    return str(v)
                else:
                    print('unknown v: ' + str(v))
                return ''
            
            for d in usersList:
                script += 'INSERT OR IGNORE INTO users ('
                keys = d.keys()
                script += ','.join(k for k in keys)
                script += ') VALUES('
                isFirst = True
                script += ','.join(vtostr(d[k]) for k in keys)
                script += ');\nUPDATE users SET '
                isFirst = True
                for k in keys:
                    if k == 'id':
                        continue
                    if isFirst == False:
                        script += ', '
                    script += k + ' = '
                    script += vtostr(d[k])
                    isFirst = False
                script += ' WHERE id=' + str(d['id']) + ';\n'
            #print('script is: ' + script)
            self.cursor.executescript(script)
        except Exception as e:
            print('update users database exception: ' + str(e))
        else:
            print('update script finished successfully')
        '''
        INSERT OR IGNORE INTO my_table (name,age) VALUES('Karen',34)
        UPDATE my_table SET age = 34 WHERE name='Karen'
        '''
        pass

    def getUsersByIds(self, ids):
        script = 'SELECT * FROM users WHERE id IN (' + ','.join(str(id) for id in ids) + ')'
        self.cursor.execute(script)
        result = self.cursor.fetchall()
        return result
    
    def getShortUsersByIds(self, ids):
        script = 'SELECT id,first_name,last_name,photo_50,photo_100,photo_200,name FROM users WHERE id IN (' + ','.join(str(id) for id in ids) + ')'
        self.cursor.execute(script)
        result = self.cursor.fetchall()
        return result
