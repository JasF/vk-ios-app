from objcbridge import BridgeBase, Subscriber
import vk
from vk import Session
import json
from objc import managers
from threading import Event
from caches.users import UsersDatabase
import services

class Storage():
    def __init__(self):
        self.accessToken = ''


class AuthorizationHandlerProtocolDelegate(BridgeBase):
    pass

class NewsHandlerProtocolDelegate(BridgeBase):
    pass

class NewsHandlerProtocol:
    def menuTapped(self):
        managers.shared().screensManager().showMenu()


class MenuHandlerProtocol:
    def newsTapped(self):
        managers.shared().screensManager().showNewsViewController(handler=NewsHandlerProtocol())

    def dialogsTapped(self):
        managers.shared().screensManager().showDialogsViewController(handler=DialogsHandlerProtocol())

class DialogsHandlerProtocol:
    def menuTapped(self):
        managers.shared().screensManager().showMenu()


class AuthorizationHandlerProtocol:
    def accessTokenGathered(self, aAccessToken):
        vk.setToken(aAccessToken)
        #managers.shared().screensManager().showDialogsViewController(handler=DialogsHandlerProtocol())
        managers.shared().screensManager().showNewsViewController(handler=NewsHandlerProtocol())

def launch():
    print ('pre init')
    services.initializeServices()
    print ('pos init')
    Subscriber().setClassHandler(MenuHandlerProtocol())
    managers.shared().screensManager().showAuthorizationViewController(handler=AuthorizationHandlerProtocol())
    pass
