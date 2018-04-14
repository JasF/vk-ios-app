import json
dict = json.loads('{"id": 78365, "body": "\u042f \u0443\u0436\u0435 \u0441\u043f\u0430\u043b\u0430 \u0432 \u044d\u0442\u043e \u0432\u0440\u0435\u043c\u044f", "user_id": 12994606, "from_id": 12994606, "date": 1523695079, "read_state": 0, "out": 0}')

resultDict = {}
for k in dict.keys():
    v = dict[k]
    type = ''
    if isinstance(v, str):
        type = 'text'
    elif isinstance(v, int):
        type = 'integer'
    resultDict[k]=type

print(', '.join("'" + k + "': '" + resultDict[k] + "'" for k in resultDict))
