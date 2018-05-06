import traceback
from objc import printpatch
import settings, sys

launched = False
def performLaunch():
    launched = True
    try:
        import main
        main.launch()
    except Exception as e:
        print('fail launch: ' + str(e))
        print(traceback.format_exc())

try:
    import objcbridge
    settings.setDocumentsDirectory(sys.argv[1])
    settings.load()
    
    def startSessionHandler():
        if launched == False:
            performLaunch()

    objcbridge.subscribe('startSession', startSessionHandler)
    objcbridge.main()
except Exception as e:
    print('server exception: ' + str(e))
