class FlutterTwilioVoiceContactData {
  final String phoneNumber;
  final String displayName;
  final String photoURL;

  FlutterTwilioVoiceContactData(
    this.phoneNumber, {
    this.displayName = "",
    this.photoURL = "",
  });
}
