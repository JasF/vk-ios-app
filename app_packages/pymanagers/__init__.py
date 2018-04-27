from objcbridge import BridgeBase, Subscriber
from .pynotificationsmanager import PyNotificationsManager
from .pydialogsmanager import PyDialogsManager

Subscriber().setClassAllocator( PyNotificationsManager, lambda: PyNotificationsManager() )
Subscriber().setClassAllocatorWithDelegate( PyDialogsManager, lambda delegateId: PyDialogsManager().setDelegateId(delegateId) )
