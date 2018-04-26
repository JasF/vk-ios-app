import Async_DisplayKit

public class StackLayout: A_SDisplayNode, A_SPlayground {
  public let titleNode    = A_STextNode()
  public let subtitleNode = A_STextNode()

  override public init() {
    super.init()
    backgroundColor = .white

    automaticallyManagesSubnodes = true
    setupNodes()
  }

  private func setupNodes() {
    titleNode.backgroundColor = .blue
    titleNode.attributedText = NSAttributedString.attributedString(string: "Headline!", fontSize: 14, color: .white, firstWordColor: nil)

    subtitleNode.backgroundColor = .yellow
    subtitleNode.attributedText = NSAttributedString(string: "Lorem ipsum dolor sit amet, sed ex laudem utroque meliore, at cum lucilius vituperata. Ludus mollis consulatu mei eu, esse vocent epicurei sed at. Ut cum recusabo prodesset. Ut cetero periculis sed, mundi senserit est ut. Nam ut sonet mandamus intellegebat, summo voluptaria vim ad.")
  }

  // This is used to expose this function for overriding in extensions
  override public func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec {
    return A_SLayoutSpec()
  }

  public func show() {
    display(inRect: .zero)
  }
}
