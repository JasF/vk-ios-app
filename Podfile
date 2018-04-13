source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
target 'vk' do
    use_frameworks!
    swift_version = '3.0'
	pod 'Texture', :path => 'Components/AsyncDisplayKit'
    pod 'NMessenger', :path => 'Components/NMessenger'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
