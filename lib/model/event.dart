import 'package:flutter_twilio_voice/model/call.dart';
import 'package:flutter_twilio_voice/model/type.dart';

class FlutterTwilioVoiceEvent {
  final FlutterTwilioVoiceEventStatus type;
  final FlutterTwilioVoiceCall? call;

  FlutterTwilioVoiceEvent(this.type, this.call);
}
