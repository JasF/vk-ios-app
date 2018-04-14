import PlaygroundSupport
import Async_DisplayKit

public protocol A_SPlayground: class {
  func display(inRect: CGRect)
}

extension A_SPlayground {
  public func display(inRect rect: CGRect) {
    var rect = rect
    if rect.size == .zero {
      rect.size = CGSize(width: 400, height: 400)
    }

    guard let nodeSelf = self as? A_SDisplayNode else {
      assertionFailure("Class inheriting A_SPlayground must be an A_SDisplayNode")
      return
    }

    let constrainedSize = A_SSizeRange(min: rect.size, max: rect.size)
    _ = A_SCalculateRootLayout(nodeSelf, constrainedSize)
    nodeSelf.frame = rect
    PlaygroundPage.current.needsIndefiniteExecution = true
    PlaygroundPage.current.liveView = nodeSelf.view
  }
}
