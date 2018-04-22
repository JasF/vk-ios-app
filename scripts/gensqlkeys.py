import json
import os
import sys

data = json.loads('{"id": 1939, "from_id": 7162990, "owner_id": 7162990, "date": 1523515923, "post_type": "post", "text": "https://www.youtube.com/watch?v=JhLQeF1FDUwnu0419u043eu0433u0430 u0412u0430u0441u0438u0448u0442u0445u0430", "can_delete": 1, "can_pin": 1, "attachments": [{"type": "video", "video": {"id": 456239080, "owner_id": 7162990, "title": "u0419u043eu0433u0430 u043fu043e-u0432u0437u0440u043eu0441u043bu043eu043cu0443. u0419u043eu0433u0430 u0412u0430u0441u0438u0448u0442u0445u0430", "duration": 1840, "description": "u0415u0441u043bu0438 u0443 u0432u0430u0441 u043fu043eu044fu0432u0438u043bu043eu0441u044c u043du0430u043cu0435u0440u0435u043du0438u0435 u043fu043eu0434u0434u0435u0440u0436u0430u0442u044c u043du0430u0448 u043fu0440u043eu0435u043au0442 u0440u0430u0441u043fu0440u043eu0441u0442u0440u0430u043du0435u043du0438u044f u0432u0438u0434u0435u043e u043bu0435u043au0446u0438u0439 u043fu0440u0435u043fu043eu0434u0430u0432u0430u0442u0435u043bu0435u0439 u043au043bu0443u0431u0430 oum.ru, u0432u044b u043cu043eu0436u0435u0442u0435 u0441u0434u0435u043bu0430u0442u044c u044du0442u043e u043du0430 u044du0442u043e u0441u0442u0440u0430u043du0438u0446u0435nhttp://www.oum.ru/about/help/nnu0410u043du0434u0440u0435u0439 u0412u0435u0440u0431u0430. u041bu0435u043au0446u0438u044f u0419u043eu0433u0430 u0412u0430u0441u0438u0448u0442u0445u0430.nu0439u043eu0433u0430-u043bu0430u0433u0435u0440u044c u0410u0443u0440u0430, 2012.nnu0411u043eu043bu0435u0435 u043fu043eu0434u0440u043eu0431u043du0443u044e u0438u043du0444u043eu0440u043cu0430u0446u0438u044e u043eu0431u043e u043cu043du0435, u0432u044b u043cu043eu0436u0435u0442u0435 u043du0430u0439u0442u0438 u043du0430 u043cu043eu0435u0439 u0441u0442u0440u0430u043du0438u0446u0435: http://www.oum.ru/about/tutors/andrey-verba/", "date": 1523515923, "comments": 0, "views": 30, "photo_130": "https://pp.userapi.com/c629423/u100167215/video/s_59bce0e2.jpg", "photo_320": "https://pp.userapi.com/c629423/u100167215/video/l_5f929714.jpg", "photo_640": "https://pp.userapi.com/c629423/u100167215/video/y_ae084374.jpg", "access_key": "47066b6ce6dd973224", "platform": "YouTube", "can_edit": 1, "can_add": 1}}], "post_source": {"type": "vk"}, "comments": {"count": 0, "groups_can_post": true, "can_post": 1}, "likes": {"count": 0, "user_likes": 0, "can_like": 1, "can_publish": 0}, "reposts": {"count": 0, "user_reposted": 0}, "views": {"count": 92}}')


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
