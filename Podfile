# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'Oxy Feed' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  swift_version = '3.3'

  # Pods for MessageGroups
  pod 'Texture', :path => 'Components/Texture'
  pod 'NMessenger', :path => 'Components/nMessenger'
  #pod 'Chatto', :path => 'Components/Chatto'
  #pod 'ChattoAdditions', :path => 'Components/Chatto'
  pod 'LoremIpsum', '= 1.0.0'
  pod 'MWPhotoBrowser', :path => 'Components/MWPhotoBrowser'
  pod 'DOCheckboxControl'
  pod 'SDCAlertView', :path => 'Components/SDCAlertView'
  pod 'TTTAttributedLabel', :path => 'Components/TTTAttributedLabel'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.name == "NMessenger"
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '3.3'
      end
    end
  end
end
