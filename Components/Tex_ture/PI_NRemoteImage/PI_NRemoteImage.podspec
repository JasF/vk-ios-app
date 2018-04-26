#
# Be sure to run `pod lib lint PI_NRemoteImage.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "PI_NRemoteImage"
  s.version          = "3.0.0-beta.13"
  s.summary          = "A thread safe, performant, feature rich image fetcher"
  s.homepage         = "https://github.com/pinterest/PI_NRemoteImage"
  s.license          = 'Apache 2.0'
  s.author           = { "Garrett Moon" => "garrett@pinterest.com" }
  s.source           = { :git => "https://github.com/pinterest/PI_NRemoteImage.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/garrettmoon'

  ios_deployment = "7.0"
  tvos_deployment = "9.0"
  osx_deployment = "10.9"
  s.ios.deployment_target = ios_deployment
  s.tvos.deployment_target = tvos_deployment
  s.requires_arc = true
  
  # Include optional FLAnimatedImage module
  s.default_subspecs = 'FLAnimatedImage','PI_NCache'
  
  ### Subspecs
  s.subspec 'Core' do |cs|
    cs.dependency 'PI_NOperation'
    cs.ios.deployment_target = ios_deployment
    cs.tvos.deployment_target = tvos_deployment
    cs.osx.deployment_target = osx_deployment
    cs.source_files = 'Source/Classes/**/*.{h,m}'
    cs.public_header_files = 'Source/Classes/**/*.h'
    cs.exclude_files = 'Source/Classes/ImageCategories/FLAnimatedImageView+PI_NRemoteImage.h', 'Source/Classes/ImageCategories/FLAnimatedImageView+PI_NRemoteImage.m','Source/Classes/PI_NCache/*.{h,m}'
    cs.frameworks = 'ImageIO', 'Accelerate'
  end
  
  s.subspec 'iOS' do |ios|
    ios.ios.deployment_target = ios_deployment
    ios.tvos.deployment_target = tvos_deployment
    ios.dependency 'PI_NRemoteImage/Core'
    ios.frameworks = 'UIKit'
  end

  s.subspec 'OSX' do |cs|
    cs.osx.deployment_target = osx_deployment
    cs.dependency 'PI_NRemoteImage/Core'
    cs.frameworks = 'Cocoa', 'CoreServices'
  end

  # The tvOS spec is no longer necessary, iOS should be used instead.
  s.subspec 'tvOS' do |tvos|
    tvos.dependency 'PI_NRemoteImage/iOS'
  end

  s.subspec "FLAnimatedImage" do |fs|
    fs.platforms = "ios"
    fs.dependency 'PI_NRemoteImage/Core'
    fs.source_files = 'Source/Classes/ImageCategories/FLAnimatedImageView+PI_NRemoteImage.h', 'Source/Classes/ImageCategories/FLAnimatedImageView+PI_NRemoteImage.m'
    fs.dependency 'FLAnimatedImage', '>= 1.0'
  end

  s.subspec 'WebP' do |webp|
    webp.xcconfig = {
        'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) PI_N_WEBP=1', 
        'USER_HEADER_SEARCH_PATHS' => '$(inherited) $(SRCROOT)/libwebp/src'
    }
    webp.dependency 'PI_NRemoteImage/Core'
    webp.dependency 'libwebp'
  end
  
  s.subspec "PI_NCache" do |pc|
    pc.dependency 'PI_NRemoteImage/Core'
    pc.dependency 'PI_NCache', '=3.0.1-beta.6'
    pc.ios.deployment_target = ios_deployment
    pc.tvos.deployment_target = tvos_deployment
    pc.osx.deployment_target = osx_deployment
    pc.source_files = 'Source/Classes/PI_NCache/*.{h,m}'
  end
  
end
