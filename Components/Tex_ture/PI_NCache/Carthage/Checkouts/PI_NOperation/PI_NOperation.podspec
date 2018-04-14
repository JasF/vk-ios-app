Pod::Spec.new do |s|
  s.name          = 'PI_NOperation'
  s.version       = '1.1'
  s.homepage      = 'https://github.com/pinterest/PI_NOperation'
  s.summary       = 'Fast, concurrency-limited task queue for iOS and OS X.'
  s.authors       = { 'Garrett Moon' => 'garrett@pinterest.com' }
  s.source        = { :git => 'https://github.com/pinterest/PI_NOperation.git', :tag => "#{s.version}" }
  s.license       = { :type => 'Apache 2.0', :file => 'LICENSE.txt' }
  s.requires_arc  = true
  s.frameworks    = 'Foundation'
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.8'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'
  pch_PI_N = <<-EOS
#ifndef TARGET_OS_WATCH
  #define TARGET_OS_WATCH 0
#endif
EOS
  s.prefix_header_contents = pch_PI_N
  s.source_files = 'Source/**/*.{h,m,mm}'
end
