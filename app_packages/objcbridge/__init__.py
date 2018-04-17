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
http = urllib3.PoolManager()

logs = []

class Storage():
    pass

subscriber = Subscriber()
storage = Storage()
storage.socket = None


results = {}
events = {}

async def sendText(text):
    try:
        r = http.request('POST', 'http://127.0.0.1:8765/post',
                         headers={'Content-Type': 'application/json'},
                         body=text)
    except Exception as e:
        __builtin__.original_print('send exception: ' + str(e))
    finally:
        pass

def send(text):
    if isinstance(text,dict):
        try:
            text = json.dumps(text)
        except Exception as e:
            __builtin__.original_print('json.dumps failed: ' + str(e))

    loop = None
    try:
        loop = asyncio.get_event_loop()
    except:
        pass
    if not loop:
        loop = asyncio.new_event_loop()
    if loop.is_running():
        def async_print(text):
            send(text)
        thread = threading.Thread(target=async_print, args=[text])
        thread.start()
        thread.join()
    else:
       loop.run_until_complete(sendText(text))

subscriber.send = send

def main():
    while True:
        message = urllib.request.urlopen("http://127.0.0.1:8765/grep").read()
        try:
            parse(message)
        except Exception as e:
            __builtin__.original_print('parse exc: ' + str(e))

def subscribe(command, handler):
    subscriber.subscribe(command, handler)

def sendCommandWithHandler(className, action, handler, args=[], withResult=False):
    subscriber.setClassHandler(handler)
    objectForSend = {'command': 'classAction', 'class': className, 'action':action, 'args':args}
    if withResult:
        event = Event()
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
        print('event for key: ' + key + ' missing. events: ' + str(events))
        traceback.print_stack()

subscriber.setEvent = setEvent


class BridgeRequest(object):
    __slots__ = ('_api', '_method_name', '_method_args', '_class_name')
    
    def __init__(self, api, method_name, class_name):
        self._api = api
        self._class_name = class_name
        self._method_name = method_name.replace('_', ':')
        self._method_args = {}
    
    def __getattr__(self, method_name):
        return BridgeRequest(self._api, self._method_name + '.' + method_name)
    
    def __call__(self, **method_args):
        self._method_args = method_args
        handler = method_args.get('handler')
        args = method_args.get('args')
        withResult = method_args.get('withResult')
        result = sendCommandWithHandler(self._class_name, self._method_name, handler, args=args, withResult=withResult)
        return result

class BridgeBase(object):
    def __init__(self, *args, **kwargs):
        pass
    
    def __getattr__(self, method_name):
        return BridgeRequest(self, method_name, type(self).__name__)
    
    def __call__(self, method_name, **method_kwargs):
        return getattr(self, method_name)(**method_kwargs)
