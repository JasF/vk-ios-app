import json
import os
import sys

data = json.loads('{"id": 456239168, "album_id": -7, "owner_id": 7162990, "photo_75": "https://pp.userapi.com/c846324/v846324676/18cc9/ORMMSsuzRC8.jpg", "photo_130": "https://pp.userapi.com/c846324/v846324676/18cca/2FOiedBBy8U.jpg", "photo_604": "https://pp.userapi.com/c846324/v846324676/18ccb/eP6ndsmITHE.jpg", "photo_807": "https://pp.userapi.com/c846324/v846324676/18ccc/9zh4yeKur3U.jpg", "photo_1280": "https://pp.userapi.com/c846324/v846324676/18ccd/o3zn6VRjQQQ.jpg", "photo_2560": "https://pp.userapi.com/c846324/v846324676/18cce/7OtBMbiEl0U.jpg", "width": 1620, "height": 2160, "text": "", "date": 1522848612, "likes": {"user_likes": 0, "count": 6}, "reposts": {"count": 0}, "comments": {"count": 1}, "can_comment": 1, "tags": {"count": 0}}')


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
