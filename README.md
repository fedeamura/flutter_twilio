# flutter_twilio

Provides an interface to Twilio's Programmable Voice SDK to allow voice-over-IP (VoIP) calling into your Flutter applications.
This plugin was taken from the original flutter_twilio_voice, as it seems that plugin is no longer maitained, this one is.

## Features
- Receive and place calls from iOS devices, uses callkit to receive calls.
- Receive and place calls from Android devices, uses custom UI to receive calls.


### Setup
Please follow Twilio's quickstart setup for each platform, you dont need to write the native code but it will help you undestand the basic functionality of setting up your server, registering your iOS app for VOIP, etc.

### iOS Setup
Nothing to do

### Android Setup:
Register in your `AndroidManifest.xml` the service in charge of displaying incomming call notifications:

``` xml
<Application>
  .....
  <service
      android:name="federico.amura.flutter_twilio.fcm.VoiceFirebaseMessagingService"
      android:stopWithTask="false">
      <intent-filter>
          <action android:name="com.google.firebase.MESSAGING_EVENT" />
      </intent-filter>
  </service>
```
