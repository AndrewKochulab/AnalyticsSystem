# Analytics System

The main idea of `AnalyticsSystem` dependency is to provide light API to configure multi-providers inside your app. 

## Providers

An `AnalyticsSystem` helps you easily add multiple providers in 10 lines of code. There is already built-in providers:
- Mixpanel
- Bugsnag

## How to use
### Installation

To add `AnalyticsSystem` to a  [Swift Package Manager](https://swift.org/package-manager/)  based project, add:

> .package(url: "https://github.com/AndrewKochulab/AnalyticsSystem")

### Example

#### Configure an analytics system

````swift
import AnalyticsSystem
	
let analyticsService = AnalyticsSystem()
    
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
	
extension AnalyticsTrackerEventsFactory {
  // ...
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
analyticsService.track(
  event: SignUpEvent(
    userId: "user_identifier",
    method: .email
  )
)

analyticsService.track(event: CrashRecoveryEvent())
analyticsService.track(event: OnboardingFinishEvent())
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

## License

This code is distributed under the MIT license. See the  `LICENSE`  file for more info.
