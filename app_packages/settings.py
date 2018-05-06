import json

g_config = {
    'access_token': '',
    'user_id': 0
}

class Storage:
    def __init__(self):
        self.documentsDirectory = ''
        self.config = g_config

storage = Storage()

def set(a,b):
    storage.config[a]=b

def get(a,b=None):
    try:
        result = storage.config[a]
        return result
    except:
        pass
    return b

def setDocumentsDirectory(directory):
    storage.documentsDirectory = str(directory)

def documentsDirectory():
    return storage.documentsDirectory

def settingsFilePath():
    return storage.documentsDirectory + '/settings.json'

def load():
    try:
        with open (settingsFilePath(), 'r') as file:
            readedConfig = file.read()
            if isinstance(readedConfig, str):
                readedConfig = json.loads(readedConfig)
            if isinstance(readedConfig, dict):
                readedConfig['access_token']
                storage.config = readedConfig
                #print('loaded settings: ' + json.dumps(readedConfig, indent=4))
    except:
        pass

def write():
    save()

def save():
    with open (settingsFilePath(), 'w') as file:
        file.write(json.dumps(storage.config))
