import 'package:flutter_twilio_voice/flutter_twilio_voice.dart';

class FlutterTwilioVoiceCall {
  final String id;
  final String to;
  final String toDisplayName;
  final String toPhotoURL;
  final FlutterTwilioVoiceEventStatus status;
  final bool mute;
  final bool speaker;

  FlutterTwilioVoiceCall({
    required this.to,
    required this.toDisplayName,
    required this.toPhotoURL,
    required this.status,
    required this.id,
    required this.mute,
    required this.speaker,
  });

  factory FlutterTwilioVoiceCall.fromMap(Map<String, dynamic> data) {
    return FlutterTwilioVoiceCall(
      id: data["id"] ?? "",
      to: data["to"] ?? "",
      toDisplayName: data["toDisplayName"] ?? "",
      toPhotoURL: data["toPhotoURL"] ?? "",
      status: FlutterTwilioVoice.getEventType(data["status"] ?? ""),
      mute: data["mute"] ?? false,
      speaker: data["speaker"] ?? false,
    );
  }
}
