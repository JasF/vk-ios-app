import asyncio

async def exec_with_event(event):
    print('exec_with_event begin: ' + str(event))
    await event
    print('exec_with_event finish')

class RunLoop():
    def __new__(cls):
        if not hasattr(cls, 'instance') or not cls.instance:
            cls.instance = super().__new__(cls)
            cls.instance.events = []
        return cls.instance
    
    @staticmethod
    def shared():
        return RunLoop()

    def exit(self, code):
        if len(self.events) == 0:
            raise Exception('runloop', 'event not found')
            return
        event = self.events[len(self.events)-1]
        self.events.pop()
        self.code = code
        event.set_result(True)
        print('runLoop exiting...')
        pass

    def exec(self):
        print('runLoop exec')
        loop = asyncio.new_event_loop()
        if loop:
            asyncio.set_event_loop(loop)
        event = asyncio.Future()
        self.events.append(event)
        loop.run_until_complete(exec_with_event(event))
        print('runLoop exit')
        return self.code

def exit(code):
    shared().exit(code)

def exec():
    shared().exec()

def shared():
    return RunLoop.shared()
