import json
import builtins as __builtin__
from .subscriber import Subscriber

subscriber = Subscriber()

def dprint(text):
    __builtin__.original_print(text)

def parse(message):
    object = json.loads(message)
    cmd = object.get('command')
    if cmd:
        subscriber.performCommand(cmd, object)
