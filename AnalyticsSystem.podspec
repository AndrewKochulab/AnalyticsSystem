
Pod::Spec.new do |s|
  s.name             = 'AnalyticsSystem'
  s.version          = '1.0.0'
  s.summary          = 'AnalyticsSystem'

  s.description      = <<-DESC
Simplify your app analytics with multiple built-in providers.
                       DESC

  s.homepage         = 'https://github.com/AndrewKochulab/AnalyticsSystem'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors          = 'Andrew Kochulab'

  s.source           = {
    :git => 'https://github.com/AndrewKochulab/AnalyticsSystem.git',
    :tag => s.version.to_s
  }

  s.social_media_url = 'https://github.com/AndrewKochulab'
  s.ios.deployment_target = '10.0'

  s.cocoapods_version = '>= 1.4.0'
  s.swift_version = '5.2'

  s.default_subspec = 'Core'
  s.static_framework = true

  s.subspec 'Core' do |ss|
    ss.source_files = 'Sources/AnalyticsSystem/**/*.{swift, h}'
  end

  s.subspec 'Bugsnag' do |ss|
    ss.dependency 'AnalyticsSystem/Core'
    ss.dependency 'Bugsnag'
    ss.source_files = 'Sources/BugsnagProvider/BugsnagTracker.swift'
  end
  
  s.subspec 'Facebook' do |ss|
    ss.dependency 'AnalyticsSystem/Core'
    ss.dependency 'FBSDKCoreKit'
    ss.source_files = 'Sources/FacebookProvider/FacebookTracker.swift'
  end

end
