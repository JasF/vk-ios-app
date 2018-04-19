# from __future__ import absolute_import

from .api import API
from .session import Session
from .longpoll import LongPoll

# API errors should process in try-catch blocks
class Token:
    def __init__(self):
        self.token = None
        self.userId = None

tokenObject = Token()

def setToken(token):
    tokenObject.token = token
    LongPoll().connect()

def setUserId(userId):
    tokenObject.userId = userId

def token():
    return tokenObject.token

def userId():
    return tokenObject.userId

def api():
    session = Session()
    api = API(session)
    api.session.method_default_args['v'] = '5.74'
    api.session.method_default_args['access_token'] = token()
    return api

__version__ = '2.2-a1'

__all__ = ('API', 'Session', '__version__')
