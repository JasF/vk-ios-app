import os, sys, sqlite3, json

class BaseDatabase():
    @staticmethod
    def deleteDatabaseFile(self):
        path = sys.argv[1] + '/databases/' + self.filename() + '.sql'
        try:
            os.remove(path)
        except:
            #print('remove path: ' + path + ' error')
            pass

    def row_factory(self):
        def decodeIfNeeded(v,k):
            if k in self.objects():
                #print('decoding $$ ' + str(k) + ' for + ' + str(v))
                if not v:
                    return None
                return json.loads(v)
            return v
        
        return lambda c, r: dict([(col[0], decodeIfNeeded(r[idx],col[0])) for idx, col in enumerate(c.description)])
    
    def __init__(self):
        self.tableName = self.__class__.filename()
        self.conn = None
        path = sys.argv[1] + '/databases'
        os.makedirs(path, exist_ok=True)
        path += '/' + self.tableName + '.sql'
        self.rowid = self.primaryKeyName()
        try:
            self.conn = sqlite3.connect(path)
            self.conn.row_factory = self.row_factory()
            self.cursor = self.conn.cursor()
            createTableScript = 'CREATE TABLE IF NOT EXISTS ' + self.tableName + ' (' + self.rowid + ' ' + self.primaryKeyType() + ' PRIMARY KEY, ' + ', '.join(  k + ' ' + self.params()[k] for k in self.params()  ) + ')'
            self.cursor.execute(createTableScript)
        except Exception as e:
            print('connect to database ' + path + ' error: ' + str(e))
            return

    def params(self):
        print('call abstract method')
        return {}

    def objects(self):
        return []
    
    def primaryKeyName(self):
        return 'id'
    
    def primaryKeyType(self):
        return 'integer'

    def allowed(self, key):
        if key in self.params().keys() or key == self.rowid:
            return True
        return False

    def close(self):
        if self.conn:
            self.conn.close()


    def update(self, dictionariesList):
        if not isinstance(dictionariesList, list):
            raise ValueError('argument must be list, not ' + str(type(dictionariesList).__name__))
        try:
            script = ''
            def vtostr(v,k):
                if k in self.objects():
                    return json.dumps(v)
                if isinstance(v, str):
                    return v
                elif isinstance(v, int):
                    return str(v)
                else:
                    print('unknown v: ' + str(v))
                return ''
            
            for d in dictionariesList:
                script = 'INSERT OR IGNORE INTO ' + self.tableName + ' ('
                keys = d.keys()
                script += ','.join(k for k in keys if self.allowed(k))
                script += ') VALUES('
                script += ','.join('?' for k in keys if self.allowed(k)) + ')'
                parameters = [vtostr(d[k],k) for k in keys if self.allowed(k)]
                #print('update script 1 is: ' + str(script) + '; parameters: ' + str(parameters))
                self.cursor.execute(script, parameters)
                script = 'UPDATE ' + self.tableName + ' SET '
                script += ', '.join(k + ' = ?' for k in keys if self.allowed(k) and k != self.rowid)
                script += ' WHERE ' + self.rowid + '= ?'
                parameters = [vtostr(d[k],k) for k in keys if self.allowed(k) and k != self.rowid]
                parameters.append(str(d[self.rowid]))
                #print('update script 2 is: ' + str(script) + '; parameters: ' + str(parameters))
                self.cursor.execute(script, parameters)
            self.conn.commit()
        except Exception as e:
            print('update ' + self.tableName + ' database exception: ' + str(e))
        else:
            pass
            #print('update ' + self.tableName + ' finished successfully')
        pass
    
    def selectIds(self, ids, keys):
        script = 'SELECT ' + keys + ' FROM ' + self.tableName + ' WHERE ' + self.rowid + ' IN (' + ','.join(str(id) for id in ids) + ')'
        self.cursor.execute(script)
        result = self.cursor.fetchall()
        return result
    
    def selectIdsByKeys(self, ids, keys):
        return self.selectIds(ids, ','.join(k for k in keys))

