Pod::Spec.new do |s|
  s.name = "VK-ios-sdk"
  s.version = "1.4.6"
  s.summary = "Library for working with VK."
  s.license = "MIT"
  s.authors = {"Roman Truba"=>"dreddkr@gmail.com"}
  s.homepage = "https://github.com/VKCOM/vk-ios-sdk"
  s.frameworks = ["Foundation", "UIKit", "SafariServices", "CoreGraphics", "Security"]
  s.requires_arc = true
  s.source = { :path => '.' }

  s.ios.deployment_target    = '6.0'
  s.ios.vendored_framework   = 'ios/VK-ios-sdk.framework'
end
