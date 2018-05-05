import json

def doCropTags(text):
    first = text.find('[')
    second = text.find('|')
    third = text.find(']')
    if first < 0 or second < 0 or third < 0:
        return text, False
    if text.find(' ', first, second) >= 0:
        return text, False
    name = text[second+1:third]
    pathed = text[:first] + name + text[third+1:]
    return pathed, True

def cropTags(text):
    result = text
    while True:
        result, success = doCropTags(result)
        if not success:
            break
    return result


def cropTagsInResults(results, key):
    try:
        items = results['items']
        for item in items:
            value = item.get(key)
            if isinstance(value, str):
                item[key] = cropTags(value)
    except Exception as e:
        print('cropTagsInResults exception: ' + str(e))

def cropTagsOnListInResults(results, listkey, key):
    try:
        items = results['items']
        for item in items:
            subitems = item.get(listkey)
            if isinstance(subitems, list):
                for subitem in subitems:
                    value = subitem.get(key)
                    if isinstance(value, str):
                        subitem[key] = cropTags(value)
    except Exception as e:
        print('cropTagsOnListInResults exception: ' + str(e))

def cropTagsOnPostsResults(results):
    cropTagsOnListInResults(results, 'copy_history', 'text')
    cropTagsInResults(results, 'text')
