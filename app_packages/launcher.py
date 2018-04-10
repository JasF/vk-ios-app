print('Hello Python vk-world!')
import traceback
from objc import printpatch

launched = False
def performLaunch():
    launched = True
    try:
        print('launched!')
        import main
        main.launch()
    except Exception as e:
        print('fail launch: ' + str(e))
        traceback.print_stack()

try:
    import objcbridge
    
    def startSessionHandler():
        if launched == False:
            performLaunch()

    objcbridge.subscribe('startSession', startSessionHandler)
    objcbridge.main()
except Exception as e:
    print('server exception: ' + str(e))
