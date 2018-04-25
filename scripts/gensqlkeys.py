import json
import os
import sys

data = json.loads('{"type": "reply_comment", "date": 1523693282, "parent": {"id": 1942, "owner_id": 7162990, "date": 1523690680, "text": "[id3829401|0415043204330435043d04380439], 043f04400438043d04460438043f 04110443043404340438044104420441043a043e0433043e 0432043e0441044c043c0435044004380447043d043e0433043e 043f044304420438 0433043b0430044104380442: 043404320438043304300439044204350441044c 04410440043504340438043d043d044b043c 043f044304420435043c! 041f043e044d0442043e043c0443 043d0435043b044c0437044f, 04340435043b0430044f 10 043b04350442 04400438044204430430043b 043f04400430043a04420438044704350441043a0438 0435043604350434043d04350432043d043e 043f043e0442043e043c 04320437044f0442044c 0438 043e0434043d043e043204400435043c0435043d043d043e 0441043e0441043a043e044704380442044c, 043d0435 043f043e0442043e043c0443 04470442043e 044d0442043e 043d04350432043e0437043c043e0436043d043e, 0430 043f043e0442043e043c0443 04470442043e 043204410435 043d04430436043d043e 04340435043b04300442044c 043f043b04300432043d043e =)", "reply_to_user": 3829401, "reply_to_comment": 1941, "post": {"id": 1940, "from_id": 7162990, "to_id": 7162990, "date": 1523669205, "post_type": "post", "text": "04170430 043f043e0441043b04350434043d04380435 043404320430 043c04350441044f04460430 043a044304400438043b 043404320430 0440043004370430. 041f043e 0438043d04350440044604380438.", "can_delete": 1, "post_source": {"type": "mvk"}, "comments": {"count": 7, "groups_can_post": true, "can_post": 1}, "likes": {"count": 0, "user_likes": 0, "can_like": 1, "can_publish": 0}, "views": {"count": 111}}}, "feedback": {"id": 1943, "from_id": 3829401, "date": 1523669205, "text": "", "reply_to_user": 7162990, "reply_to_comment": 1942, "likes": {"count": 0, "user_likes": 0}}}')


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
