Pod::Spec.new do |spec|
  spec.name         = 'Tex_ture'
  spec.version      = '2.6'
  spec.license      =  { :type => 'BSD and Apache 2',  }
  spec.homepage     = 'http://texturegroup.org'
  spec.authors      = { 'Huy Nguyen' => 'huy@pinterest.com', 'Garrett Moon' => 'garrett@excitedpixel.com', 'Scott Goodson' => 'scottgoodson@gmail.com', 'Michael Schneider' => 'schneider@pinterest.com', 'Adlai Holler' => 'adlai@pinterest.com' }
  spec.summary      = 'Smooth asynchronous user interfaces for iOS apps.'
  spec.source       = { :git => 'https://github.com/Tex_tureGroup/Tex_ture.git', :tag => spec.version.to_s }
  spec.module_name  = 'Async_DisplayKit'
  spec.header_dir   = 'Async_DisplayKit'

  spec.documentation_url = 'http://texturegroup.org/appledoc/'

  spec.weak_frameworks = 'Photos','MapKit','AssetsLibrary'
  spec.requires_arc = true

  spec.ios.deployment_target = '8.0'

  # Uncomment when fixed: issues with tvOS build for release 2.0
  # spec.tvos.deployment_target = '9.0'

  # Subspecs
  spec.subspec 'Core' do |core|
    core.public_header_files = [
        'Source/*.h',
        'Source/Details/**/*.h',
        'Source/Layout/**/*.h',
        'Source/Base/*.h',
        'Source/Debug/**/*.h',
        'Source/TextKit/A_STextNodeTypes.h',
        'Source/TextKit/A_STextKitComponents.h'
    ]
    
    core.source_files = [
        'Source/**/*.{h,m,mm}',
        'Base/*.{h,m}',
      
        # Most TextKit components are not public because the C++ content
        # in the headers will cause build errors when using
        # `use_frameworks!` on 0.39.0 & Swift 2.1.
        # See https://github.com/facebook/Async_DisplayKit/issues/1153
        'Source/TextKit/*.h',
    ]
    core.xcconfig = { 'GCC_PRECOMPILE_PREFIX_HEADER' => 'YES' }
  end
  
  spec.subspec 'PI_NRemoteImage' do |pin|
      pin.dependency 'PI_NRemoteImage/iOS', '= 3.0.0-beta.13'
      pin.dependency 'PI_NRemoteImage/PI_NCache'
      pin.dependency 'Tex_ture/Core'
  end

  spec.subspec 'IGListKit' do |igl|
      igl.dependency 'IGListKit', '3.0.0'
      igl.dependency 'Tex_ture/Core'
  end

  spec.subspec 'Yoga' do |yoga|
      yoga.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) YOGA=1' }
      yoga.dependency 'Yoga', '1.6.0'
      yoga.dependency 'Tex_ture/Core'
  end

  # Include optional PI_NRemoteImage module
  spec.default_subspec = 'PI_NRemoteImage'

  spec.social_media_url = 'https://twitter.com/Tex_tureiOS'
  spec.library = 'c++'
  spec.pod_target_xcconfig = {
       'CLANG_CXX_LANGUAGE_STANDARD' => 'c++11',
       'CLANG_CXX_LIBRARY' => 'libc++'
  }

end
