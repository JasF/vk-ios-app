import json
import os
import sys

data = {
    "src": "https://sun9-3.userapi.com/c834501/u7162990/d18/-3/m_cb557a4dae.jpg",
        "width": 130,
            "height": 100,
                "type": "m"
                }

resultDict = {}
for k in data.keys():
    v = data[k]
    type = ''
    if isinstance(v, (str, dict, list)):
        type = 'text'
    elif isinstance(v, int):
        type = 'integer'
    resultDict[k]=type

def isObject(o):
    value = data[o]
    if isinstance(value, (dict, list)):
        return True
    return False

print('{' + ', '.join("'" + k + "': '" + resultDict[k] + "'" for k in resultDict if k != 'id') + '}')
print('[' + ', '.join("'" + k + "'" for k in resultDict if isObject(k) == True) + ']')

types = {'text': 'NSString *', 'integer': 'NSInteger '}

print( '\n'.join('@property ' + types[resultDict[k]] + k + ';' for k in resultDict))

print( '[mapping mapPropertiesFromArray:@[' + ', '.join('@"' + k + '"' for k in resultDict) + ']];')
