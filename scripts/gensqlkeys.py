import json
import os
import sys

data = {
    "id": 144831667,
        "owner_id": 7162990,
        "title": "\u0413\u043e\u0440\u043e\u0445\u043e\u0432 - \u041c\u044b \u0432\u0441\u0435, \u043f\u043e\u0440\u043e\u044e, \u0447\u0442\u043e-\u0442\u043e \u043c\u043e\u0436\u0435\u043c",
        "duration": 64,
        "description": "",
        "date": 1275513302,
        "comments": 0,
        "views": 15,
        "photo_130": "https://pp.userapi.com/v402/assets/thumbnails/ba2e8fc084033924.130.vk.jpg",
        "photo_320": "https://pp.userapi.com/v402/assets/thumbnails/ba2e8fc084033924.320.vk.jpg",
        "adding_date": 1275513302,
        "player": "https://vk.com/video_ext.php?oid=7162990&id=144831667&hash=09bba39952b24a41&__ref=vk.api&api_hash=1524902883b26a8a345fd1c353c0_G4YTMMRZHEYA",
        "can_edit": 1,
        "can_add": 1,
        "privacy_view": [
                         "all"
                         ],
                         "privacy_comment": [
                                             "all"
                                             ],
                         "can_comment": 1,
                         "can_repost": 1,
                         "likes": {
                             "user_likes": 0,
                                 "count": 0
                             },
    "reposts": {
        "count": 0,
            "user_reposted": 0
        },
        "repeat": 0
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
