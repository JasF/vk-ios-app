import os, shutil

dict = {'Texture':'Tex_ture', 'AsyncDisplayKit': 'AsyncDisplayKit', 'AS':'A_S', 'NS_A_SSUME_NONNULL':'NS_ASSUME_NONNULL', 'OBJC_A_SSOCIATION': 'OBJC_ASSOCIATION', 'A_SSIGN': 'ASSIGN', 'A_SCII': 'ASCII', 'CLA_SS': 'CLASS', 'PIN': 'PI_N', 'ImageDetectors': 'ImageDe_tectors'}
ignore = ['.DS_Store', '.png', 'TestResources', '.gif', '.jpg', '.ico', '.pdf', '.tracetemplate', '.mp4', '.xcuserstate', '1.0.docset/Contents/Info.plist', '/Tests/Info.plist', 'Tests.m', 'Operation/Source/Info.plist', 'Carthage', '.xml', '.docset']

def patchFileContent(path):
    for ig in ignore:
        if ig in path:
            return False
    with open(path) as f:
        orig = ''.join(f.readlines())
        content = str(orig)
        #print('path: ' + path)
        for key in dict.keys():
            content = content.replace(key, dict[key])
        if orig != content:
            text_file = open(path, "w")
            text_file.write(content)
            text_file.close()
            print('path: ' + path + ' written')
    return False

def replaceIfNeeded(dirName, it, was):
    dst = dirName.replace(it, was)
    if dst != dirName:
        shutil.move(dirName, dst)
        print('moving ' + dirName + ' to ' + dst)
        return True
    return False

def getWalk():
    for dirName, subdirList, fileList in os.walk('./Tex_ture'):
        for key in dict.keys():
            if replaceIfNeeded(dirName, key, dict[key]) == True:
                return False
        for fname in fileList:
            path = dirName + '/' + fname
        
            for key in dict.keys():
                if replaceIfNeeded(path, key, dict[key]) == True:
                    return False
            if patchFileContent(path) == True:
                return False
    return True

while True:
    result = getWalk()
    if result == True:
        break
    print('restarting!')


