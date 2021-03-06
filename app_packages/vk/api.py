import logging
from objc import managers
import settings
import vk

from .session import Session
from .exceptions import VkAuthError, VkAPIError

logger = logging.getLogger('vk')

class API(object):
    def __init__(self, *args, **kwargs):
        session_class = kwargs.pop('session_class', Session)
        self.session = session_class(*args, **kwargs)

    def __getattr__(self, method_name):
        return Request(self, method_name)

    def __call__(self, method_name, **method_kwargs):
        return getattr(self, method_name)(**method_kwargs)

class Request(object):
    __slots__ = ('_api', '_method_name', '_method_args')

    def __init__(self, api, method_name):
        self._api = api
        self._method_name = method_name
        self._method_args = {}

    def __getattr__(self, method_name):
        return Request(self._api, self._method_name + '.' + method_name)

    def __call__(self, **method_args):
        self._method_args = method_args
        result = {}
        try:
            result = self._api.session.make_request(self)
        except VkAPIError as e:
            print('VkAPIError exception: ' + str(e))
            if e.code == 5:
                if len(vk.token()) == 0:
                    print('token missing. do nothing')
                    raise
                settings.set('access_token', '')
                settings.set('user_id', 0)
                vk.setToken('')
                vk.setUserId(0)
                settings.write()
                managers.shared().screensManager().showAuthorizationViewController()
            raise
        return result
