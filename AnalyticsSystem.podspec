Pod::Spec.new do |s|
  s.name             = 'AnalyticsSystem'
  s.version          = '2.1.0'
  s.summary          = 'Multi-provider analytics for Apple platforms, with a dependency-free core.'

  s.description      = <<-DESC
AnalyticsSystem fans analytics events out to any number of providers behind one small,
Sendable API. The core carries no third-party dependencies; each provider is an opt-in
subspec. Built for Swift 6 strict concurrency.
                       DESC

  s.homepage         = 'https://github.com/AndrewKochulab/AnalyticsSystem'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors          = 'Andrew Kochulab'
  s.social_media_url = 'https://github.com/AndrewKochulab'

  s.source = {
    :git => 'https://github.com/AndrewKochulab/AnalyticsSystem.git',
    :tag => s.version.to_s
  }

  s.ios.deployment_target     = '15.0'
  s.osx.deployment_target     = '12.0'
  s.tvos.deployment_target    = '15.0'
  s.watchos.deployment_target = '8.0'
  s.visionos.deployment_target = '1.0'

  s.cocoapods_version = '>= 1.13.0'
  s.swift_versions    = ['6.0']

  s.default_subspec = 'Core'
  s.static_framework = true

  # CocoaPods has no equivalent of SwiftPM package traits, so each provider subspec
  # defines the same compilation condition the corresponding trait would. That keeps
  # the `#if Firebase` / `#if Facebook` guards in Sources/ identical under both
  # package managers — v1 instead deleted the Firebase and Mixpanel subspecs outright,
  # so CocoaPods and SwiftPM silently shipped different provider sets.

  s.subspec 'Core' do |ss|
    ss.source_files = 'Sources/AnalyticsSystem/**/*.swift'
  end

  s.subspec 'Firebase' do |ss|
    ss.dependency 'AnalyticsSystem/Core'
    ss.dependency 'Firebase/Analytics', '~> 12.17'
    ss.dependency 'Firebase/Crashlytics', '~> 12.17'
    ss.source_files = 'Sources/FirebaseProvider/**/*.swift'
    ss.pod_target_xcconfig = {
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) Firebase'
    }
    # Firebase Analytics has no watchOS support.
    ss.ios.deployment_target  = '15.0'
    ss.osx.deployment_target  = '12.0'
    ss.tvos.deployment_target = '15.0'
  end

  s.subspec 'Facebook' do |ss|
    ss.dependency 'AnalyticsSystem/Core'
    ss.dependency 'FBSDKCoreKit', '~> 18.1'
    ss.source_files = 'Sources/FacebookProvider/**/*.swift'
    ss.pod_target_xcconfig = {
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) Facebook'
    }
    # The Facebook SDK is iOS-only.
    ss.ios.deployment_target = '15.0'
  end

  s.subspec 'Mixpanel' do |ss|
    ss.dependency 'AnalyticsSystem/Core'
    ss.dependency 'Mixpanel-swift', '~> 6.5'
    ss.source_files = 'Sources/MixpanelProvider/**/*.swift'
    ss.pod_target_xcconfig = {
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) Mixpanel'
    }
  end

  s.subspec 'Bugsnag' do |ss|
    ss.dependency 'AnalyticsSystem/Core'
    ss.dependency 'Bugsnag', '~> 6.37'
    ss.source_files = 'Sources/BugsnagProvider/**/*.swift'
    ss.pod_target_xcconfig = {
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) Bugsnag'
    }
  end
end
