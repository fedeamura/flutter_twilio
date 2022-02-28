import 'call.dart';
import 'status.dart';

class FlutterTwilioEvent {
  final FlutterTwilioStatus status;
  final FlutterTwilioCall? call;

  FlutterTwilioEvent(this.status, this.call);
}
