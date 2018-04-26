//: [Photo With Inset Text Overlay](PhotoWithInsetTextOverlay)

import Async_DisplayKit

extension PhotoWithOutsetIconOverlay {

  override public func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec {
    let iconWidth: CGFloat = 40
    let iconHeight: CGFloat = 40
    
    iconNode.style.preferredSize = CGSize(width: iconWidth, height: iconWidth)
    photoNode.style.preferredSize = CGSize(width: 150, height: 150)

    let x: CGFloat = 150
    let y: CGFloat = 0

    iconNode.style.layoutPosition = CGPoint(x: x, y: y)
    photoNode.style.layoutPosition = CGPoint(x: iconWidth * 0.5, y: iconHeight * 0.5);

    let absoluteLayoutSpec = A_SAbsoluteLayoutSpec(children: [photoNode, iconNode])
    return absoluteLayoutSpec;
  }

}

PhotoWithOutsetIconOverlay().show()

//: [Horizontal Stack With Spacer](HorizontalStackWithSpacer)
