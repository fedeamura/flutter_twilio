class FlutterTwilioCall {
  final String id;
  final String to;
  final String toDisplayName;
  final String toPhotoURL;
  final bool mute;
  final bool speaker;

  FlutterTwilioCall({
    required this.to,
    required this.toDisplayName,
    required this.toPhotoURL,
    required this.id,
    required this.mute,
    required this.speaker,
  });

  factory FlutterTwilioCall.fromMap(Map<String, dynamic> data) {
    return FlutterTwilioCall(
      id: data["id"] ?? "",
      to: data["to"] ?? "",
      toDisplayName: data["toDisplayName"] ?? "",
      toPhotoURL: data["toPhotoURL"] ?? "",
      mute: data["mute"] ?? false,
      speaker: data["speaker"] ?? false,
    );
  }
}
