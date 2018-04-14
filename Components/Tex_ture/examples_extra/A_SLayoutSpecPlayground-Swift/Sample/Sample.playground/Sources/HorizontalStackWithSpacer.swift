import Async_DisplayKit

fileprivate let fontSize: CGFloat = 20

public class HorizontalStackWithSpacer: A_SDisplayNode, A_SPlayground {
  public let usernameNode     = A_STextNode()
  public let postLocationNode = A_STextNode()
  public let postTimeNode     = A_STextNode()

  override public init() {
    super.init()
    backgroundColor = .white

    automaticallyManagesSubnodes = true
    setupNodes()
  }

  private func setupNodes() {
    usernameNode.backgroundColor = .yellow
    usernameNode.attributedText = NSAttributedString.attributedString(string: "hannahmbanana", fontSize: fontSize, color: .darkBlueColor(), firstWordColor: nil)

    postLocationNode.backgroundColor = .lightGray
    postLocationNode.maximumNumberOfLines = 1;
    postLocationNode.attributedText = NSAttributedString.attributedString(string: "San Fransisco, CA", fontSize: fontSize, color: .lightBlueColor(), firstWordColor: nil)

    postTimeNode.backgroundColor = .brown
    postTimeNode.attributedText = NSAttributedString.attributedString(string: "30m", fontSize: fontSize, color: .lightGray, firstWordColor: nil)
  }

  // This is used to expose this function for overriding in extensions
  override public func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec {
    return A_SLayoutSpec()
  }

  public func show() {
    display(inRect: CGRect(x: 0, y: 0, width: 450, height: 100))
  }
}
