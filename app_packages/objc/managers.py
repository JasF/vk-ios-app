from .screensmanager import ScreensManager
import objcbridge

class YesNoDialogView():
    def showYesNoDialogWithMessage(self, message):
        objcbridge.sendCommandWithHandler('PasswordDialog', 'showYesNoDialogWithMessage:', self.handler, args=[message])

class PasswordDialogView():
    def showPasswordDialogWithMessage(self, message):
        objcbridge.sendCommandWithHandler('PasswordDialog', 'showPasswordDialogWithMessage:', self.handler, args=[message])

class TextFieldDialogView():
    def showWithMessage(self, message, placeholder):
        objcbridge.sendCommandWithHandler('TextFieldDialog', 'showTextFieldDialogWithMessage:placeholder:', self.handler, args=[message, placeholder])
        pass

class WaitingDialogView():
    def showWaitingDialogWithMessage(self, message):
        objcbridge.sendCommandWithHandler('WaitingDialog', 'showWaitingDialogWithMessage:', None, args=[message])

    def waitingDialogClose(self):
        objcbridge.sendCommandWithHandler('WaitingDialog', 'waitingDialogClose', None)

class Managers():
    def __new__(cls):
        if not hasattr(cls, 'instance') or not cls.instance:
            cls.instance = super().__new__(cls)
        return cls.instance

    @staticmethod
    def shared():
        return Managers()
    
    def screensManager(self):
        if not hasattr(self, '_screensManager') or not self._screensManager:
            self._screensManager = ScreensManager()
        return self._screensManager
    
    def alertManager(self):
        pass
    
    def createWaitingDialog(self):
        return WaitingDialogView()
    
    def createPasswordDialog(self):
        return PasswordDialogView()
    
    def createYesNoDialog(self):
        return YesNoDialogView()
    
    def createTextFieldDialog(self):
        return TextFieldDialogView()
    
    def feedbackManager(self):
        pass
    
    def setDocumentsDirectory(self, directory):
        self.documentsPath = directory
    
    def documentsDirectory(self):
        return self.documentsPath

def shared():
    return Managers.shared()
