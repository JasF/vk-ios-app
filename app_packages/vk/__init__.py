# from __future__ import absolute_import

from .api import API
from .session import Session

class Token:
    pass

tokenObject = Token()

def setToken(token):
    tokenObject.token = token

def token():
    return tokenObject.token

def api():
    session = Session(access_token=token())
    api = API(session)
    api.session.method_default_args['v'] = '5.74'
    return api

__version__ = '2.2-a1'

__all__ = ('API', 'Session', '__version__')
