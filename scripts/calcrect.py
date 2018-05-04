class Size:
    def __repr__(self):
        return "{w: " + str(self.w) + '; h: ' + str(self.h) + '}'
    def __init__(self, width, height):
        self.w = width
        self.h = height

class Rect:
    def __repr__(self):
        return "{x: " + str(self.x) + '; y:' + str(self.y) + "; w: " + str(self.w) + '; h: ' + str(self.h) + '}'
    def __init__(self, x, y, width, height):
        self.w = width
        self.h = height
        self.x = x
        self.y = y
cs = 320


s1 = Size(400, 200)
s2 = Size(100, 100)

def getNormalized(ar):
    res = []
    first = ar[0]
    for size in ar:
        normW = size.w * (first.h/size.h)
        normH = size.h * (first.h/size.h)
        res.append(Size(normW, normH))
    return res

def getWsum(ar):
    wsum = 0
    for size in ar:
        wsum = wsum + size.w
    return wsum

def getFactors(ar, wsum):
    result = []
    for s in ar:
        f = s.w/wsum
        result.append(f)
    return result

def getResults(sizes, factors, cs, dh):
    sumX = 0
    results = []
    for s,f in zip(sizes, factors):
        dw = cs * f
        results.append(Rect(sumX, 0, dw, dh))
        sumX = sumX + dw
        print('re: ' + str(dw))
    return results

ar = [s1,s2]
nar = getNormalized(ar)
wsum = getWsum(nar)
factors = getFactors(nar, wsum)
dh = s1.h * (cs/wsum)
result = getResults(nar, factors, cs, dh)
print('result: ' + str(result))
print('dest height: ' + str( dh ))


