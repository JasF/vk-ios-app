//: [Index](Index)
/*:
 In this example, you can experiment with stack layouts.
 */
import Async_DisplayKit

extension StackLayout {

  override public func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec {
    // Try commenting out the flexShrink to see its consequences.
    subtitleNode.style.flexShrink = 1.0

    let stackSpec = A_SStackLayoutSpec(direction: .horizontal,
                                      spacing: 5,
                                      justifyContent: .start,
                                      alignItems: .start,
                                      children: [titleNode, subtitleNode])

    let insetSpec = A_SInsetLayoutSpec(insets: UIEdgeInsets(top: 5,
                                                           left: 5,
                                                           bottom: 5,
                                                           right: 5),
                                      child: stackSpec)
    return insetSpec
  }

}

StackLayout().show()

//: [Photo With Inset Text Overlay](PhotoWithInsetTextOverlay)