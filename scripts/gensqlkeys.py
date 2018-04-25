import json
import os
import sys

data = {
    "id": 456239168,
        "owner_id": 113132980,
        "title": "\u0422\u0415\u041d\u042c \u0437\u0430\u043f\u0440\u0435\u0449\u0451\u043d\u043d\u044b\u0439 \u043c\u0443\u043b\u044c\u0442\u0444\u0438\u043b\u044c\u043c \u041e \u0442\u043e\u043c, \u0447\u0442\u043e \u0441\u0435\u0439\u0447\u0430\u0441 \u0420\u0415\u0410\u041b\u042c\u041d\u041e \u043f\u0440\u043e\u0438\u0441\u0445\u043e\u0434\u0438\u0442 \u0432 \u041c\u0418\u0420\u0415",
        "duration": 532,
        "description": "\u041c\u041e\u0429\u041d\u042b\u0419 \u041c\u0423\u041b\u042c\u0422\u0424\u0418\u041b\u042c\u041c \u0441\u0440\u044b\u0432\u0430\u044e\u0449\u0438\u0439 \u043d\u0430\u0448\u0438 \u043c\u0430\u0441\u043a\u0438, \u0448\u0430\u0431\u043b\u043e\u043d\u044b \u043e\u0431\u0449\u0435\u0441\u0442\u0432\u0430, \u043f\u043e\u043a\u0430\u0437\u044b\u0432\u0430\u044e\u0449\u0438\u0439 \u043f\u0443\u0442\u044c \u043e\u0442 \u043b\u0436\u0438\u0432\u043e\u0441\u0442\u0438 \u0438 \u043f\u043e\u0442\u0440\u0435\u0431\u043b\u0435\u043d\u0438\u044f \u0434\u043e \u043f\u0440\u043e\u0441\u0432\u0435\u0449\u0435\u043d\u0438\u044f \u0438 \u043e\u0441\u043e\u0437\u043d\u0430\u043d\u043d\u043e\u0441\u0442\u0438. \u041f\u0443\u0442\u044c \u043b\u0435\u0436\u0430\u0449\u0438\u0439 \u0447\u0435\u0440\u0435\u0437 \"\u0441\u0435\u0440\u0434\u0446\u0435\", \u0447\u0435\u0440\u0435\u0437 \u043d\u0430\u0448 \u0432\u043d\u0443\u0442\u0440\u0435\u043d\u043d\u0438\u0439 \u043c\u0438\u0440, \u043e\u043a\u0435\u0430\u043d \u0441\u0432\u0435\u0442\u0430 \u0438 \u043b\u044e\u0431\u0432\u0438.",
        "date": 1521055257,
        "comments": 0,
        "views": 205993,
        "width": 1280,
        "height": 720,
        "photo_130": "https://pp.userapi.com/c845524/v845524422/2a25/hT5YxyrLOwc.jpg",
        "photo_320": "https://pp.userapi.com/c845524/v845524422/2a23/ctTSZ1LbHXM.jpg",
        "photo_800": "https://pp.userapi.com/c845524/v845524422/2a22/AjvOnCgOYHg.jpg",
        "adding_date": 1522933587,
        "first_frame_320": "https://pp.userapi.com/c824600/v824600422/e5959/fQoFCIuoZb8.jpg",
        "first_frame_160": "https://pp.userapi.com/c824600/v824600422/e595a/zIoGQeGUHuc.jpg",
        "first_frame_130": "https://pp.userapi.com/c824600/v824600422/e595b/eKZUJvcc4Uw.jpg",
        "first_frame_800": "https://pp.userapi.com/c824600/v824600422/e5958/k3D1S68J1DI.jpg",
        "player": "https://vk.com/video_ext.php?oid=113132980&id=456239168&hash=3b8018fcfd6baeaa&__ref=vk.api&api_hash=152465202254add1c2a97a14dda0_G4YTMMRZHEYA",
        "can_add": 1
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
