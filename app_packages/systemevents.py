from objcbridge import BridgeBase, Subscriber
from objcbridge import BridgeBase, ObjCBridgeProtocol

class SystemEvents():
    def __new__(cls):
        if not hasattr(cls, 'instance') or not cls.instance:
            cls.instance = super().__new__(cls)
            cls.handlers = set()
        return cls.instance

    def addHandler(self, handler):
        try:
            self.handlers.add(handler)
        except:
            pass
    def removeHandler(self, handler):
        try:
            self.handlers.remove(handler)
        except:
            pass
    def call(self, methodname):
        for h in self.handlers:
            try:
                func = getattr(h, methodname)
                if callable(func):
                    func()
            except:
                pass

class PySystemEvents(ObjCBridgeProtocol):
    def __init__(self):
        self.systemEvents = SystemEvents()
    
    # ObjCBridgeProtocol
    def release(self):
        print('PySystemEvents release')
        pass

    # PySystemEvents
    def applicationDidEnterBackground(self):
        self.systemEvents.call('applicationDidEnterBackground')
    def applicationWillEnterForeground(self):
        self.systemEvents.call('applicationWillEnterForeground')
    def applicationDidBecomeActive(self):
        self.systemEvents.call('applicationDidBecomeActive')
    def applicationWillResignActive(self):
        self.systemEvents.call('applicationWillResignActive')
    def applicationWillTerminate(self):
        self.systemEvents.call('applicationWillTerminate')

Subscriber().setClassAllocator( PySystemEvents, lambda: PySystemEvents() )
