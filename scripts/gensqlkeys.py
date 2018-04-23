import json
import os
import sys

data = json.loads('{"id": 1942, "from_id": 7162990, "date": 1523690680, "text": "[id3829401|u0415u0432u0433u0435u043du0438u0439], u043fu0440u0438u043du0446u0438u043f u0411u0443u0434u0434u0438u0441u0442u0441u043au043eu0433u043e u0432u043eu0441u044cu043cu0435u0440u0438u0447u043du043eu0433u043e u043fu0443u0442u0438 u0433u043bu0430u0441u0438u0442: u0434u0432u0438u0433u0430u0439u0442u0435u0441u044c u0441u0440u0435u0434u0438u043du043du044bu043c u043fu0443u0442u0435u043c! u041fu043eu044du0442u043eu043cu0443 u043du0435u043bu044cu0437u044f, u0434u0435u043bu0430u044f 10 u043bu0435u0442 u0440u0438u0442u0443u0430u043b u043fu0440u0430u043au0442u0438u0447u0435u0441u043au0438 u0435u0436u0435u0434u043du0435u0432u043du043e u043fu043eu0442u043eu043c u0432u0437u044fu0442u044c u0438 u043eu0434u043du043eu0432u0440u0435u043cu0435u043du043du043e u0441u043eu0441u043au043eu0447u0438u0442u044c, u043du0435 u043fu043eu0442u043eu043cu0443 u0447u0442u043e u044du0442u043e u043du0435u0432u043eu0437u043cu043eu0436u043du043e, u0430 u043fu043eu0442u043eu043cu0443 u0447u0442u043e u0432u0441u0435 u043du0443u0436u043du043e u0434u0435u043bu0430u0442u044c u043fu043bu0430u0432u043du043e =)", "reply_to_user": 3829401, "reply_to_comment": 1941}')


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
