# Analytics System

The main idea of `AnalyticsSystem` dependency is to provide light API to configure multi-providers inside your app. 

## Providers

An `AnalyticsSystem` helps you easily add multiple providers in 10 lines of code. There is already built-in providers:
- Mixpanel
- Bugsnag
- Facebook
- Firebase

## How to use
### Installation

To add `AnalyticsSystem` to a  [Swift Package Manager](https://swift.org/package-manager/)  based project, add:

````swift
.package(url: "https://github.com/AndrewKochulab/AnalyticsSystem.git")
````

Cocoapods:

````
pod 'AnalyticsSystem/Core'
````

You can also import some provider, like:

````
pod 'AnalyticsSystem/Bugsnag'
pod 'AnalyticsSystem/Facebook'
````

### Example

#### Configure an analytics system

````swift
import AnalyticsSystem
	
let analyticsSystem = AnalyticsSystem()
    
try analyticsSystem.configureTrackers { cfg in 
  let commonEventsFactory = AnalyticsTrackerEventsFactory()

  try cfg.addTracker(MixpanelTracker(apiToken: "your_api_token", eventsFactory: commonEventsFactory))
  try cfg.addTracker(BugsnagTracker(apiToken: "your_api_token", eventsFactory: commonEventsFactory))

  let fbTracker = FacebookTracker(eventsFactory: FacebookTrackerEventsFactory())
  fbTracker.isEventAvailable = { eventType in
    eventType == .signUp
  }
            
  try cfg.addTracker(fbTracker)
}
	
analyticsSystem.initialize()
````

#### Create events

````swift
enum RegistrationEventMethod: String {
  case email = "Email",
  facebook = "Facebook",
  twitter = "Twitter"
}
	
struct SignUpEvent: AnalyticsEvent {
  let userId: String
  let method: RegistrationEventMethod 
  var type: AnalyticsEventType { .signUp }
     
  init(
    userId: String,
    method: RegistrationEventMethod
  ) {
    self.userId = userId
    self.method = method
  }
}
	
final class AnalyticsTrackerEventsFactory {
  func signUpEventBuilder(event: SignUpEvent) -> AnalyticsEventBuilder { 
    .init(
      name: "sign_up",
      attributes: [
        "user_id" : event.userId,
        "method" : event.method.rawValue
      ]
    )
  }
}
````

#### Track events

````swift
analyticsSystem.track(
  event: SignUpEvent(
    userId: "user_identifier",
    method: .email
  )
)

analyticsSystem.track(event: CrashRecoveryEvent())
analyticsSystem.track(event: OnboardingFinishEvent())
````

#### Update builder for specific provider

````swift
final class FacebookTrackerEventsFactory: AnalyticsTrackerEventsFactory {   
  override func signUpEventBuilder(event: SignUpEvent) -> AnalyticsEventBuilder {
    .init(
      name: AppEvents.Name.completedRegistration.rawValue,
      attributes: [
        "user_id" : event.userId.rawValue,
        AppEvents.ParameterName.registrationMethod.rawValue : event.method.rawValue
      ]
    )
  }
}
````

#### Create own analytics provider

````swift
import AnalyticsSystem
import FirebaseAnalytics
import FirebaseCrashlytics

final class FirebaseTracker: FactoryAnalyticsTracker<AnalyticsTrackerEventsFactory> {
  private var crashlytics: Crashlytics {
    .crashlytics()
  }
    
  override func initialize(with options: LaunchOptions? = nil) {
    FirebaseApp.configure()
  }
    
  override func setEnabled(_ isEnabled: Bool) {
    Analytics.setAnalyticsCollectionEnabled(isEnabled)
  }
    
  override func logIn(user: AnalyticsUser) {
    Analytics.setUserID(user.id)
    crashlytics.setUserID(user.id)
  }
    
  override func logOut(user: AnalyticsUser) {
    Analytics.setUserID(nil)
    crashlytics.setUserID("")
  }
  
  override func track(eventBuilder: AnalyticsEventBuilder) {
    Analytics.logEvent(
      eventBuilder.name,
      parameters: eventBuilder.attributes
    )
  }
}
````


## Contribution

⭐️ If you like what you see, star us on GitHub.

Find a bug, a typo, or something that’s not documented well? We’d love for you to open an issue telling me what I can improve!

Contributions are welcome, and they are greatly appreciated!


## License

This code is distributed under the MIT license. See the  `LICENSE`  file for more info.
