from objc import managers as Managers
import caches
import services
import viewmodels
import traceback, objcbridge
import settings, vk, screenshow, analytics, systemevents

try:
    import pymanagers
except Exception as e:
    print(traceback.format_exc())

def launch():
    objcbridge.send('{}') # first initialization message
    accessToken = settings.get('access_token')
    userId = settings.get('user_id')
    if isinstance(accessToken, str) and len(accessToken) > 0 and isinstance(userId, int):
        vk.setToken(accessToken)
        vk.setUserId(userId)
        screenshow.showScreenAfterAuthorization()
        return
    Managers.shared().screensManager().showAuthorizationViewController()
