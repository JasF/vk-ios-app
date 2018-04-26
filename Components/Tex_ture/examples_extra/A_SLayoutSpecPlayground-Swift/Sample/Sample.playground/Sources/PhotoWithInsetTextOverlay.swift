import Async_DisplayKit

public class PhotoWithInsetTextOverlay: A_SDisplayNode, A_SPlayground {
  public let photoNode = A_SNetworkImageNode()
  public let titleNode = A_STextNode()

  override public init() {
    super.init()
    backgroundColor = .white

    automaticallyManagesSubnodes = true
    setupNodes()
  }

  private func setupNodes() {
    photoNode.url = URL(string: "http://asyncdisplaykit.org/static/images/layout-examples-photo-with-inset-text-overlay-photo.png")
    photoNode.backgroundColor = .black

    titleNode.backgroundColor = .blue
    titleNode.maximumNumberOfLines = 2
    titleNode.truncationAttributedText = NSAttributedString.attributedString(string: "...", fontSize: 16, color: .white, firstWordColor: nil)
    titleNode.attributedText = NSAttributedString.attributedString(string: "family fall hikes", fontSize: 16, color: .white, firstWordColor: nil)
  }

  // This is used to expose this function for overriding in extensions
  override public func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec {
    return A_SLayoutSpec()
  }

  public func show() {
    display(inRect: CGRect(x: 0, y: 0, width: 120, height: 120))
  }
}
