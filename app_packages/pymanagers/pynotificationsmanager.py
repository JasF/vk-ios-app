import vk, json, traceback

class PyNotificationsManager:
    def didRegisterForRemoteNotificationsWithDeviceToken(self, token):
        print('didRegisterForRemoteNotificationsWithDeviceToken: ' + str(token))
        pass
    
    def didFailToRegisterForRemoteNotifications(self, error):
        print('didFailToRegisterForRemoteNotifications: ' + str(error))
        pass
    
    def didReceiveRemoteNotification(self, userInfo):
        print('didReceiveRemoteNotification: ' + str(userInfo))
        pass
