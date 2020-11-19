
Pod::Spec.new do |s|
  s.name             = 'AnalyticsSystem'
  s.version          = '1.0.0'
  s.summary          = 'AnalyticsSystem'

  s.description      = <<-DESC
Simplify your app analytics with multiple built-in providers.
                       DESC

  s.homepage         = 'https://github.com/AndrewKochulab/AnalyticsSystem'
  s.license          = 'MIT'
  s.authors          = 'Andrew Kochulab'

  s.source           = {
    :git => 'https://github.com/AndrewKochulab/AnalyticsSystem.git',
    :branch => 'master'
  }

  s.social_media_url = 'https://github.com/AndrewKochulab'
  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.12'
  s.tvos.deployment_target = '10.0'

  s.cocoapods_version = '>= 1.4.0'
  s.swift_version = '5.2'

  s.default_subspec = 'Core'

  s.subspec 'Core' do |ss|
    ss.dependency 'AnalyticsSystem/Core'
    ss.source_files = 'Sources/AnalyticsSystem/**/*.{swift, h}'
  end

  s.subspec 'Bugsnag' do |ss|
    ss.dependency 'AnalyticsSystem/Core'
    ss.dependency 'Bugsnag'
    ss.ios.dependency 'AnalyticsBugsnagProvider'
    ss.source_files = 'Sources/BugsnagProvider/BugsnagTracker.swift'
  end
  
  s.subspec 'Facebook' do |ss|
    ss.dependency 'AnalyticsSystem/Core'
    ss.dependency 'FBSDKCoreKit'
    ss.ios.dependency 'AnalyticsFacebookProvider'
    ss.source_files = 'Sources/FacebookProvider/FacebookTracker.swift'
  end
  
  s.subspec 'Firebase' do |ss|
    ss.dependency 'AnalyticsSystem/Core'
    ss.dependency 'FirebaseAnalytics'
    ss.dependency 'FirebaseCrashlytics'
    ss.ios.dependency 'AnalyticsFirebaseProvider'
    ss.source_files = 'Sources/FirebaseProvider/FirebaseTracker.swift'
  end

  s.subspec 'Mixpanel' do |ss|
    ss.dependency 'AnalyticsSystem/Core'
    ss.dependency 'Mixpanel', '~> 3.1'
    ss.ios.dependency 'AnalyticsMixpanelProvider'
    ss.source_files = 'Sources/MixpanelProvider/MixpanelTracker.swift'
  end

end
