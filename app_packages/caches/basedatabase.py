import os, sys, sqlite3

class BaseDatabase():
    @staticmethod
    def deleteDatabaseFile(self):
        path = sys.argv[1] + '/databases/' + self.filename() + '.sql'
        try:
            os.remove(path)
        except:
            #print('remove path: ' + path + ' error')
            pass

    
    def __init__(self):
        self.tableName = self.__class__.filename()
        self.conn = None
        path = sys.argv[1] + '/databases'
        os.makedirs(path, exist_ok=True)
        path += '/' + self.tableName + '.sql'
        try:
            self.conn = sqlite3.connect(path)
            self.conn.row_factory = lambda c, r: dict([(col[0], r[idx]) for idx, col in enumerate(c.description)])
            self.cursor = self.conn.cursor()
            createTableScript = 'CREATE TABLE IF NOT EXISTS ' + self.tableName + ' (id integer PRIMARY KEY, ' + ', '.join(  k + ' ' + self.params()[k] for k in self.params()  ) + ')'
            self.cursor.execute(createTableScript)
        except Exception as e:
            print('connect to database ' + path + ' error: ' + str(e))
            return

    def params(self):
        print('call abstract method')
        return {}

    def allowed(self, key):
        if key in self.params().keys() or key == 'id':
            return True
        return False

    def close(self):
        if self.conn:
            self.conn.close()


    def update(self, dictionariesList):
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
            
            for d in dictionariesList:
                script += 'INSERT OR IGNORE INTO ' + self.tableName + ' ('
                keys = d.keys()
                script += ','.join(k for k in keys if self.allowed(k))
                script += ') VALUES('
                script += ','.join(vtostr(d[k]) for k in keys if self.allowed(k))
                script += ');\nUPDATE ' + self.tableName + ' SET '
                script += ', '.join(k + ' = ' + vtostr(d[k]) for k in keys if self.allowed(k) and k != 'id')
                script += ' WHERE id=' + str(d['id']) + ';\n'
            print('updating script is: ' + str(script))
            self.cursor.executescript(script)
        except Exception as e:
            print('update ' + self.tableName + ' database exception: ' + str(e))
        else:
            pass
            #print('update ' + self.tableName + ' finished successfully')
        pass
    
    def selectIds(self, ids, keys):
        script = 'SELECT ' + keys + ' FROM ' + self.tableName + ' WHERE id IN (' + ','.join(str(id) for id in ids) + ')'
        self.cursor.execute(script)
        result = self.cursor.fetchall()
        return result
    
    def selectIdsByKeys(self, ids, keys):
        return self.selectIds(ids, ','.join(k for k in keys))
