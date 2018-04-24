import vk, json, traceback
from objc import managers

class PyNotificationsManager:
    def didRegisterForRemoteNotificationsWithDeviceToken(self, token):
        print('didRegisterForRemoteNotificationsWithDeviceToken: ' + str(token))
        api = vk.api()
        try:
            response = api.account.registerDevice(token=token, device_model='iPhone7,2', device_year='2017', device_id='9238dhf029hfg2739fn', system_version='ios11.3', settings=json.dumps({'msg':'on'}))
            print('registerDevice response: ' + str(response))
        except Exception as e:
            print('send device token exception: ' + str(e))
        pass
    
    def didFailToRegisterForRemoteNotifications(self, error):
        print('didFailToRegisterForRemoteNotifications: ' + str(error))
        pass
    
    def didReceiveRemoteNotification(self, userInfo):
        try:
            data = userInfo['data']
            type = data['type']
            if type == 'msg':
                context = data['context']
                senderId = context['sender_id']
                managers.shared().screensManager().showDialogViewController_(args=[senderId])
            else:
                print('unknown push type: ' + str(type))
        
        except Exception as e:
            print('parse incoming push exception: ' + str(e))
        pass
'''
{
    "aps": {
        "thread-id": "vk",
        "sound": "push_msg",
        "alert": {
            "title": "Павел Молодкин",
            "body": "Павел Молодкин: Приходят пуши пркинь ! =)"
        },
        "category": "msg",
        "badge": 1
    },
    "data": {
        "group_id": "msg_127688261",
        "id": "msg_127688261_79088",
        "time": 1524485745,
        "from_id": 127688261,
        "context": {
            "sender_id": 127688261,
            "msg_id": 79088
        },
        "type": "msg",
        "to_id": 7162990,
        "url": "https://vk.com/im?sel=127688261&msgid=79088"
    }
}
'''
