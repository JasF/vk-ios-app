import builtins as __builtin__
import threading

class PrintPatcher():
    def callback(self, text):
        pass

patcher = None

def dprint(*args, **kwargs):
    text = '' + str(*args)# + ' ' + str(kwargs)
    __builtin__.original_print('' + str(*args), **kwargs)
    
    if patcher:
        patcher.callback(text)

patcher = PrintPatcher()
__builtin__.original_print = __builtin__.print
#__builtin__.print = dprint

def init(callback):
    patcher.callback = callback
    pass
