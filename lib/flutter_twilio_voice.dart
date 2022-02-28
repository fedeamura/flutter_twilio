import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_twilio_voice/model/call.dart';

import 'model/contact_data.dart';
import 'model/event.dart';
import 'model/type.dart';

export 'model/call.dart';
export 'model/event.dart';
export 'model/type.dart';

class FlutterTwilioVoice {
  static const MethodChannel _channel = MethodChannel('flutter_twilio_voice');

  static const MethodChannel _eventChannel = MethodChannel('flutter_twilio_voice_response');

  static late StreamController<FlutterTwilioVoiceEvent> _streamController;

  static FlutterTwilioVoiceEvent? _event;

  static FlutterTwilioVoiceEvent? get event => _event;

  static void init() {
    _streamController = StreamController.broadcast();
    _eventChannel.setMethodCallHandler((event) async {
      log("Call event: ${event.method} . Arguments: ${event.arguments}");

      try {
        final FlutterTwilioVoiceEventStatus eventType = getEventType(event.method);
        FlutterTwilioVoiceCall? call;
        try {
          call = FlutterTwilioVoiceCall.fromMap(Map<String, dynamic>.from(event.arguments));
        } catch (error) {}
        _streamController.add(FlutterTwilioVoiceEvent(eventType, call));
      } catch (error, stack) {
        log("Error parsing call event. ${event.arguments}", error: error, stackTrace: stack);
      }
    });

    _streamController.stream.listen((event) {
      _event = event;
    });
  }

  static FlutterTwilioVoiceEventStatus getEventType(String event) {
    if (event == "callConnecting") return FlutterTwilioVoiceEventStatus.connecting;
    if (event == "callDisconnected") return FlutterTwilioVoiceEventStatus.disconnected;
    if (event == "callRinging") return FlutterTwilioVoiceEventStatus.ringing;
    if (event == "callConnected") return FlutterTwilioVoiceEventStatus.connected;
    if (event == "callReconnecting") return FlutterTwilioVoiceEventStatus.reconnecting;
    if (event == "callReconnected") return FlutterTwilioVoiceEventStatus.reconnected;
    return FlutterTwilioVoiceEventStatus.unknown;
  }

  static Stream<FlutterTwilioVoiceEvent> get onCallEvent {
    return _streamController.stream.asBroadcastStream();
  }

  static Stream<FlutterTwilioVoiceEvent> get onCallConnecting {
    return _streamController.stream.asBroadcastStream().where((event) => event.type == FlutterTwilioVoiceEventStatus.connecting);
  }

  static Future<FlutterTwilioVoiceCall> makeCall({
    required String to,
    Map<String, dynamic> data = const <String, dynamic>{},
  }) async {
    final args = <String, Object>{
      "to": to,
      "data": data,
    };

    final result = await _channel.invokeMethod('makeCall', args);
    return FlutterTwilioVoiceCall.fromMap(Map<String, dynamic>.from(result));
  }

  static Future<void> hangUp() async {
    await _channel.invokeMethod('hangUp');
  }

  static Future<void> register({
    required String identity,
    required String accessToken,
    required String fcmToken,
  }) async {
    final args = <String, Object>{
      "identity": identity,
      "accessToken": accessToken,
      "fcmToken": fcmToken,
    };
    await _channel.invokeMethod('register', args);
  }

  static Future<void> unregister() async {
    await _channel.invokeMethod('unregister');
  }

  static Future<bool> toggleMute() async {
    return await _channel.invokeMethod('toggleMute');
  }

  static Future<bool> isMuted() async {
    return await _channel.invokeMethod('isMuted');
  }

  static Future<bool> toggleSpeaker() async {
    return await _channel.invokeMethod('toggleSpeaker');
  }

  static Future<bool> isSpeaker() async {
    return await _channel.invokeMethod('isSpeaker');
  }

  static Future<FlutterTwilioVoiceCall?> getActiveCall() async {
    try {
      final data = await _channel.invokeMethod('activeCall');
      if (data == null || data == "") return null;
      return FlutterTwilioVoiceCall.fromMap(Map<String, dynamic>.from(data));
    } catch (error, stack) {
      log("Error parsing call", error: error, stackTrace: stack);
      return null;
    }
  }

  static Future<void> setContactData(
    List<FlutterTwilioVoiceContactData> data, {
    String defaultDisplayName = "Unknown number",
  }) async {
    final args = <String, dynamic>{};
    for (var element in data) {
      args[element.phoneNumber] = {
        "displayName": element.displayName.trim(),
        "photoURL": element.photoURL.trim(),
      };
    }
    await _channel.invokeMethod(
      'setContactData',
      {
        "contacts": args,
        "defaultDisplayName": defaultDisplayName,
      },
    );
  }
}
