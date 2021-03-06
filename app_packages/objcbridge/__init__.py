import asyncio
import builtins as __builtin__
from .parser import parse
from .subscriber import Subscriber
from .subscriber import ObjCBridgeProtocol
import json
import threading
from threading import Event
import urllib.request
import json
import traceback
import urllib3
import pythonbridgeextension

http = urllib3.PoolManager()

logs = []

class Storage():
    pass

subscriber = Subscriber()
storage = Storage()
storage.socket = None


results = {}
events = {}

def sendText(text):
    try:
        response = pythonbridgeextension.post(json.dumps(text))
    except Exception as e:
        __builtin__.original_print('sendText exception: ' + str(e))
        print(traceback.format_exc())
    finally:
        pass

def send(text):
    sendText(text)

subscriber.send = send

def handleincomingdata(message):
    def doParse():
        try:
            parse(message)
        except Exception as e:
            print('handleincomingdata c++2python exception: ' + str(e))
            print(traceback.format_exc())
    threading.Thread(target=doParse).start()

def main():
    parse('{"command":"startSession"}') # Magic launch command
    asyncio.get_event_loop().run_forever()

def subscribe(command, handler):
    subscriber.subscribe(command, handler)

def sendCommandWithHandler(className, action, handler, args=[], withResult=False, delegateId=0):
    subscriber.setClassHandler(handler)
    objectForSend = {'command': 'classAction', 'class': className, 'action':action, 'args':args}
    if delegateId > 0:
        objectForSend['delegateId'] = delegateId
    if withResult:
        event = Event()
        if delegateId > 0:
            key = className + '_' + str(delegateId) + action
        else:
            key = className + action
        events[key] = event
        send(objectForSend)
        event.wait()
        result = results.get(key)
        del results[key]
        return result
    else:
        send(objectForSend)

def setEvent(className, action, result):
    key = className + action
    event = events.get(key)
    if event:
        results[key] = result
        del events[key]
        event.set()
    else:
        print('event for key: ' + key + ' missing. Maybe do you forget pass named argument withResult=True in method call? events: ' + str(events))
        traceback.print_stack()

subscriber.setEvent = setEvent


class BridgeRequest(object):
    __slots__ = ('_api', '_method_name', '_method_args', '_class_name', '_delegate_id')
    
    def __init__(self, api, method_name, class_name, delegateId):
        self._api = api
        self._class_name = class_name
        self._method_name = method_name.replace('_', ':')
        self._method_args = {}
        self._delegate_id = delegateId
    
    def __getattr__(self, method_name):
        return BridgeRequest(self._api, self._method_name + '.' + method_name)
    
    def __call__(self, **method_args):
        self._method_args = method_args
        handler = method_args.get('handler')
        args = method_args.get('args')
        withResult = method_args.get('withResult')
        result = sendCommandWithHandler(self._class_name, self._method_name, handler, args=args, withResult=withResult, delegateId=self._delegate_id)
        return result

class BridgeBase(object):
    def __init__(self, *args, **kwargs):
        self.delegateId = 0
        if len(args):
            self.delegateId = args[0]
    
    def __getattr__(self, method_name):
        return BridgeRequest(self, method_name, type(self).__name__, self.delegateId)
    
    def __call__(self, method_name, **method_kwargs):
        return getattr(self, method_name)(**method_kwargs)
