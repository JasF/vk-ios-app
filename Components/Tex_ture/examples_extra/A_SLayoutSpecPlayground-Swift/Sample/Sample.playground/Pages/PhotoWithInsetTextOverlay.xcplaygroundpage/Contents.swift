//: [Stack Layout](StackLayout)

import Async_DisplayKit

let userImageHeight = 60

extension PhotoWithInsetTextOverlay {

  override public func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec {
    photoNode.style.preferredSize = CGSize(width: userImageHeight * 2, height: userImageHeight * 2)
    let backgroundImageAbsoluteSpec = A_SAbsoluteLayoutSpec(children: [photoNode])

    let insets = UIEdgeInsets(top: CGFloat.infinity, left: 12, bottom: 12, right: 12)
    let textInsetSpec = A_SInsetLayoutSpec(insets: insets,
                                          child: titleNode)

    let textOverlaySpec = A_SOverlayLayoutSpec(child: backgroundImageAbsoluteSpec, overlay: textInsetSpec)

    return textOverlaySpec
  }

}

PhotoWithInsetTextOverlay().show()

//: [Photo With Outset Icon Overlay](PhotoWithOutsetIconOverlay)