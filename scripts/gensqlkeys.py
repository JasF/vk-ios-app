import json
import os
import sys

data = {
    "city": "\u0411\u043e\u0431\u0440\u0443\u0439\u0441\u043a",
        "country": "\u0411\u0435\u043b\u0430\u0440\u0443\u0441\u044c",
        "created": 0,
        "icon": "https://vk.com/images/places/place.png",
        "id": 0,
        "latitude": 0,
        "longitude": 0,
        "title": "\u0443\u043b\u0438\u0446\u0430 \u0421\u043e\u0432\u0435\u0442\u0441\u043a\u0430\u044f, \u0411\u043e\u0431\u0440\u0443\u0439\u0441\u043a"
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
