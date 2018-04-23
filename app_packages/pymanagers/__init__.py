from objcbridge import BridgeBase, Subscriber
from .pynotificationsmanager import PyNotificationsManager

Subscriber().setClassAllocator( PyNotificationsManager, lambda: PyNotificationsManager() )
