Pod::Spec.new do |s|
  s.name = 'MonocodeLink'
  s.version = '0.1.0'
  s.summary = 'MonoCode direct QUIC connection'
  s.description = s.summary
  s.license = { :type => 'MIT' }
  s.author = 'MonoCode'
  s.homepage = 'https://usemono.dev'
  s.platforms = { :ios => '16.4' }
  s.source = { :git => 'https://github.com/hardbeat920/monocode.git' }
  s.static_framework = true
  s.dependency 'ExpoModulesCore'
  s.source_files = '**/*.swift'
  s.resource_bundles = { 'MonocodeTranscriptAssets' => ['Resources/transcript-artwork.json'] }
  s.vendored_frameworks = 'MonocodeLinkCore.xcframework'
  s.frameworks = 'Security', 'SystemConfiguration', 'UIKit', 'CoreText'
  xcconfig = { 'DEFINES_MODULE' => 'YES' }
  # Personal builds on an SDK older than iOS 27.1 (scripts/testflight.sh).
  if ENV['MONOCODE_NO_HINGE'] == '1'
    xcconfig['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = '$(inherited) MONOCODE_NO_HINGE'
  end
  s.pod_target_xcconfig = xcconfig
end
