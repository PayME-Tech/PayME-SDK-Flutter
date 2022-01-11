#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint payme_sdk_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'payme_sdk_flutter'
  s.version          = '0.0.1'
  s.summary          = 'PayME SDK Flutter is plugin for application integrate with PayME Platform.'
  s.description      = <<-DESC
  PayME SDK Flutter is plugin for application integrate with PayME Platform.
                       DESC
  s.homepage         = 'https://github.com/tamdesktop/PayME-SDK-Flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Tam Nguyen' => 'tamdesktop@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'PayMESDK', '0.9.50'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
