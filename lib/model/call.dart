import 'package:equatable/equatable.dart';
import 'package:flutter_twilio/flutter_twilio.dart';
import 'package:flutter_twilio/model/status.dart';

class FlutterTwilioCall extends Equatable {
  final String id;
  final String fromDisplayName;
  final String toDisplayName;
  final bool outgoing;
  final FlutterTwilioStatus status;
  final bool mute;
  final bool speaker;

  FlutterTwilioCall({
    required this.id,
    required this.fromDisplayName,
    required this.toDisplayName,
    required this.mute,
    required this.speaker,
    required this.status,
    required this.outgoing,
  });

  factory FlutterTwilioCall.fromMap(Map<String, dynamic> data) {
    return FlutterTwilioCall(
      id: data["id"] ?? "",
      fromDisplayName: data["fromDisplayName"] ?? "",
      toDisplayName: data["toDisplayName"] ?? "",
      outgoing: data["outgoing"] ?? false,
      mute: data["mute"] ?? false,
      speaker: data["speaker"] ?? false,
      status: FlutterTwilio.getEventType(data["status"] ?? ""),
    );
  }

  @override
  List<Object?> get props => [
        id,
        fromDisplayName,
        toDisplayName,
        outgoing,
        mute,
        speaker,
        status,
      ];
}
