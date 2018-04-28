import json
import os
import sys

#for k in keys:

data = {
    "id": 7162990,
    "first_name": "\u0410\u043d\u0434\u0440\u0435\u0439",
    "last_name": "\u0412\u043e\u0435\u0432\u043e\u0434\u0430",
    "sex": 2,
    "nickname": "",
    "domain": "voevoda",
    "screen_name": "voevoda",
    "bdate": "1.1.1989",
    "city": {
        "id": 1107,
        "title": "\u0411\u043e\u0431\u0440\u0443\u0439\u0441\u043a"
    },
    "country": {
        "id": 3,
        "title": "\u0411\u0435\u043b\u0430\u0440\u0443\u0441\u044c"
    },
    "timezone": 3,
    "photo_50": "https://pp.userapi.com/c830509/v830509923/c8d7b/9yx_oyCvavo.jpg",
    "photo_100": "https://pp.userapi.com/c830509/v830509923/c8d7a/YgRJHrGb-Ho.jpg",
    "photo_200": "https://pp.userapi.com/c830509/v830509923/c8d79/We3OSbFX1jE.jpg",
    "photo_max": "https://pp.userapi.com/c830509/v830509923/c8d79/We3OSbFX1jE.jpg",
    "photo_200_orig": "https://pp.userapi.com/c830509/v830509923/c8d77/OWPv6JqbUQY.jpg",
    "photo_400_orig": "https://pp.userapi.com/c830509/v830509923/c8d78/dZx31myftDM.jpg",
    "photo_max_orig": "https://pp.userapi.com/c830509/v830509923/c8d78/dZx31myftDM.jpg",
    "photo_id": "7162990_456239177",
    "has_photo": 1,
    "has_mobile": 1,
    "is_friend": 0,
    "friend_status": 0,
    "online": 0,
    "wall_comments": 1,
    "can_post": 1,
    "can_see_all_posts": 1,
    "can_see_audio": 1,
    "can_write_private_message": 1,
    "can_send_friend_request": 1,
    "mobile_phone": "",
    "home_phone": "",
    "skype": "ICQ56874",
    "site": "",
    "status": "",
    "last_seen": {
        "time": 1524920341,
        "platform": 7
    },
    "crop_photo": {
        "photo": {
            "id": 456239177,
            "album_id": -6,
            "owner_id": 7162990,
            "photo_75": "https://pp.userapi.com/c830509/v830509923/c8d6d/IFoTphZtktI.jpg",
            "photo_130": "https://pp.userapi.com/c830509/v830509923/c8d6e/ymLAZjJkpG4.jpg",
            "photo_604": "https://pp.userapi.com/c830509/v830509923/c8d6f/JzWh0lTMw9E.jpg",
            "photo_807": "https://pp.userapi.com/c830509/v830509923/c8d70/L9Q2Jo3qY0c.jpg",
            "photo_1280": "https://pp.userapi.com/c830509/v830509923/c8d71/iJFIUch8JI8.jpg",
            "photo_2560": "https://pp.userapi.com/c830509/v830509923/c8d72/CvhBQ2hairk.jpg",
            "width": 1620,
            "height": 2160,
            "text": "",
            "date": 1523171979,
            "lat": 53.184753,
            "long": 29.226108,
            "post_id": 1936
        },
        "crop": {
            "x": 0.0,
            "y": 0.0,
            "x2": 100.0,
            "y2": 100.0
        },
        "rect": {
            "x": 0.0,
            "y": 13.98,
            "x2": 100.0,
            "y2": 88.98
    }
},
    "verified": 0,
    "followers_count": 75,
    "blacklisted": 0,
    "blacklisted_by_me": 0,
    "is_favorite": 0,
    "is_hidden_from_feed": 0,
    "common_count": 167,
    "career": [],
    "military": [],
    "university": 0,
    "university_name": "",
    "faculty": 0,
    "faculty_name": "",
    "graduation": 0,
    "home_town": "\u0411\u043e\u0431\u0440\u0443\u0439\u0441\u043a",
    "relation": 1,
    "personal": {
        "political": 1,
        "langs": [
                  "\u010ce\u0161tina",
                  "English"
                  ],
                  "life_main": 6,
                  "smoking": 2,
                  "alcohol": 1
    },
    "interests": "\u0422\u0440\u0430\u0434\u0438\u0446\u0438\u0438 \u0418\u043d\u0434\u0443\u0438\u0437\u043c\u0430, \u042f\u0437\u044b\u043a\u043e\u0432\u0435\u0434\u0435\u043d\u0438\u0435",
    "music": "Tribal House, Psy-Trance, Dream Chillout",
    "activities": "\u0426\u0438\u0444\u0440\u043e\u0432\u044b\u0435 \u043a\u043e\u043c\u043c\u0443\u043d\u0438\u043a\u0430\u0446\u0438\u0438",
    "movies": "The Zeitgeist Film, \u0421\u0430\u043c\u0441\u0430\u0440\u0430",
    "tv": "",
    "books": "\u0421\u0430\u0434\u0434\u0445\u0430\u0440\u043c\u0430-\u043f\u0443\u043d\u0434\u0430\u0440\u0438\u043a\u0430 \u0441\u0443\u0442\u0440\u0430 \u0430 \u0442\u0430\u043a \u0436\u0435 \u043f\u0438\u0441\u0430\u0442\u0435\u043b\u0438 \u0415\u0433\u043e\u0440 \u0420\u0430\u0434\u043e\u0432, \u041c\u0430\u043c\u043b\u0435\u0435\u0432 \u042e\u0440\u0438\u0439 \u0412\u0438\u0442\u0430\u043b\u044c\u0435\u0432\u0438\u0447, \u0412\u0438\u043a\u0442\u043e\u0440 \u041f\u0435\u043b\u0435\u0432\u0438\u043d",
    "games": "",
    "universities": [],
    "schools": [],
    "about": "",
    "relatives": [],
    "quotes": "\u0412\u0435\u0433\u0435\u0442\u0430\u0440\u0438\u0430\u043d\u0441\u0442\u0432\u043e \u0441\u0438\u043b\u0430"
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
