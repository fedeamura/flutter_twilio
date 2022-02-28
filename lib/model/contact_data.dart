class FlutterTwilioContactData {
  final String phoneNumber;
  final String displayName;
  final String photoURL;

  FlutterTwilioContactData(
    this.phoneNumber, {
    this.displayName = "",
    this.photoURL = "",
  });
}
