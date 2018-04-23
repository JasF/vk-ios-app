import threading
import builtins as __builtin__
from functools import partial
import traceback

def dprint(text):
    __builtin__.original_print(text)

class ObjCBridgeProtocol():
    def release(self):
        print('called "release" without overriding')
        pass

class Subscriber():
    def __new__(cls):
        if not hasattr(cls, 'instance') or not cls.instance:
            cls.instance = super().__new__(cls)
            cls.instance.handlers = {}
            cls.instance.allocators = {}
            cls.instance.allocatorsWithDelegate = {}
        return cls.instance
    
    def subscribe(self, command, handler):
        self.handlers[command] = handler

    def performHandler(self, handler):
        try:
            thread = threading.Thread(target=handler)
            thread.start()
        except Exception as e:
            print('invoke handler exeption: ' + str(e))
                    
    def performCommand(self, cmd, object):
        if cmd == 'classAction':
            self.processClassAction(object)
            return
        if cmd == 'instantiateHandler':
            self.processInstantiateHandler(object)
        if cmd == 'instantiateHandlerWithDelegate':
            self.processInstantiateHandlerWithDelegate(object)
        if cmd == 'releaseHandler':
            self.processReleaseHandler(object)
        if cmd in self.handlers:
            handler = self.handlers[cmd]
            self.performHandler(handler)
        elif cmd == 'response':
            self.handleResponse(object)
            
    def handleResponse(self, object):
        className = object['class']
        action = object['action']
        result = object['result']
        self.setEvent(className, action, result)

    def processClassAction(self, object):
        withResult = object["withResult"]
        try:
            handler = self.handlers.get(object["class"])
            if not handler:
                raise Exception('handler cannot be nil', object["class"])
            action = object["action"]
            args = object['args']
            if handler and action:
                def performActionOnHandler(handler, action):
                    action = action.replace(':', '')
                    func = getattr(handler, action)
                    result = None
                    if callable(func):
                        result = func(*args)
                    if withResult == True:
                        self.send({'command':'response','request':object,'result':result})
                        pass
                    pass
                self.performHandler(partial(performActionOnHandler, handler, action))
        except Exception as e:
            dprint('processClassAction exception: ' + str(e) + '; handlers: ' + str(self.handlers) + '; object: ' + str(object))

    def processInstantiateHandler(self, object):
        try:
            className = object["class"]
            key = object["key"]
            try:
                allocator = self.allocators[className]
            except:
                raise ValueError('self.allocators does not have: ' + str(className))
            parameters = object.get('parameters')
            if parameters:
                handler = allocator(parameters)
            else:
                handler = allocator()
            self.handlers[key] = handler
        except Exception as e:
            dprint('instantiate handler exception: ' + str(e) + '; allocators: ' + str(self.allocators) + '; object: ' + str(object))


    def processInstantiateHandlerWithDelegate(self, object):
        try:
            className = object['class']
            key = object['key']
            delegateId = object['delegateId']
            try:
                allocator = self.allocatorsWithDelegate[className]
            except:
                raise ValueError('self.allocatorsWithDelegate does not have: ' + str(className))
            parameters = object.get('parameters')
            if parameters:
                handler = allocator(delegateId, parameters)
            else:
                handler = allocator(delegateId)
            self.handlers[key] = handler
        except Exception as e:
            dprint('instantiate handler WITH DELEGATE exception: ' + str(e) + '; allocators: ' + str(self.allocators) + '; object: ' + str(object))


    def processReleaseHandler(self, object):
        try:
            key = object["key"]
            handler = self.handlers.get(key)
            if handler:
                del self.handlers[key]
                print('handler with key: ' + str(key) + ' successfully deleted')
                try:
                    release = handler.release
                except:
                    print('release not found in handler: ' + str(handler))
                else:
                    handler.release()
            else:
                print('trying release unixestent handler for key: ' + str(key))
        except Exception as e:
            dprint('releasing handler exception: ' + str(e) + '; allocators: ' + str(self.allocators) + '; object: ' + str(object))
    def setClassAllocator(self, cls, func):
        self.allocators[cls.__name__] = func
    
    def setClassAllocatorWithDelegate(self, cls, func):
        self.allocatorsWithDelegate[cls.__name__] = func
    
    def setClassHandler(self, handler):
        if isinstance(handler, list):
            for h in handler:
                self.handlers[h.__class__.__name__] = h
        else:
            if handler:
                self.handlers[handler.__class__.__name__] = handler
