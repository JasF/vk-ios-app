from objcbridge import BridgeBase, Subscriber

class PyAnalyticsDelegate(BridgeBase):
    pass

class AnalyticsHolder():
    def __init__(self):
        self.analytics = None

g_analytics = AnalyticsHolder()

class PyAnalytics():
    def __init__(self, delegateId):
        g_analytics.analytics = self
        print('python-side analytics allocation')
        self.delegate = PyAnalyticsDelegate(delegateId)
        pass

    def logEvent(self, name):
        self.delegate.logEvent_(args=[name])

Subscriber().setClassAllocatorWithDelegate( PyAnalytics, lambda delegateId: PyAnalytics(delegateId) )

def log(name):
    print('analytic log g_analytic: ' + str(g_analytics))
    if g_analytics.analytics:
        g_analytics.analytics.logEvent(name)
