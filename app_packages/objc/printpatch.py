import builtins as __builtin__
import threading
import pythonbridgeextension

class PrintPatcher():
    def callback(self, text):
        pass

patcher = None

def dprint(*args, **kwargs):
    text = '' + str(*args)# + ' ' + str(kwargs)
    #__builtin__.original_print('' + str(*args), **kwargs)
    
    pythonbridgeextension.print(text)
    #if patcher:
        #patcher.callback(text)

patcher = PrintPatcher()
__builtin__.original_print = __builtin__.print
__builtin__.print = dprint

def init(callback):
    patcher.callback = callback
    pass
