Pod::Spec.new do |s|
  s.name          = 'PI_NCache'
  s.version       = '3.0.1-beta.6'
  s.homepage      = 'https://github.com/pinterest/PI_NCache'
  s.summary       = 'Fast, thread safe, parallel object cache for iOS and OS X.'
  s.authors       = { 'Garrett Moon' => 'garrett@pinterest.com', 'Justin Ouellette' => 'jstn@tumblr.com' }
  s.source        = { :git => 'https://github.com/pinterest/PI_NCache.git', :tag => "#{s.version}" }
  s.license       = { :type => 'Apache 2.0', :file => 'LICENSE.txt' }
  s.requires_arc  = true
  s.frameworks    = 'Foundation'
  s.ios.weak_frameworks   = 'UIKit'
  s.osx.weak_frameworks   = 'AppKit'
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.8'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'
  pch_PI_N = <<-EOS
#ifndef TARGET_OS_WATCH
  #define TARGET_OS_WATCH 0
#endif
EOS
  s.prefix_header_contents = pch_PI_N
  s.subspec 'Core' do |sp|
      sp.source_files  = 'Source/*.{h,m}'
      sp.dependency 'PI_NOperation', '~> 1.1.1'
  end
  s.subspec 'Arc-exception-safe' do |sp|
      sp.dependency 'PI_NCache/Core'
      sp.source_files = 'Source/PI_NDiskCache.m'
      sp.compiler_flags = '-fobjc-arc-exceptions'
  end
end
