import 'package:flutter_twilio/flutter_twilio.dart';
import 'package:flutter_twilio/model/status.dart';

class FlutterTwilioCall {
  final String id;
  final String to;
  final String toDisplayName;
  final String toPhotoURL;
  final FlutterTwilioStatus status;
  final bool mute;
  final bool speaker;

  FlutterTwilioCall({
    required this.to,
    required this.toDisplayName,
    required this.toPhotoURL,
    required this.id,
    required this.mute,
    required this.speaker,
    required this.status,
  });

  factory FlutterTwilioCall.fromMap(Map<String, dynamic> data) {
    return FlutterTwilioCall(
      id: data["id"] ?? "",
      to: data["to"] ?? "",
      toDisplayName: data["toDisplayName"] ?? "",
      toPhotoURL: data["toPhotoURL"] ?? "",
      mute: data["mute"] ?? false,
      status: FlutterTwilio.getEventType(data["status"] ?? ""),
      speaker: data["speaker"] ?? false,
    );
  }
}
