rm -rf build
rm -rf vk-build
xcodebuild -project "./vk.xcworkspace" -scheme vk TEST_AFTER_BUILD=NO clean build -configuration 'Release' SYMROOT="$(PWD)/build"
sh ./Scripts/package.sh "build/Release-iphoneos/vk.app" "build/Release-iphoneos/vk.app.dSYM" "vk-build"

echo ">>>zip & send"

zip -ry vk-build/vk-build.dSYM.zip vk-build/vk-build.dSYM
curl \
  -F "status=2" \
  -F "notify=1" \
  -F "notes_type=0" \
  -F "ipa=@./vk-build/vk-build.ipa" \
  -F "dsym=@./vk-build/vk-build.dSYM.zip" \
  -H "X-HockeyAppToken: 209477a38199410587f7c04f9c4670a5" \
https://rink.hockeyapp.net/api/2/apps/b3125c1736c24cafbd158dd12bbf4af7/app_versions
