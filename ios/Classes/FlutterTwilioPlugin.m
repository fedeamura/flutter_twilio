#import "FlutterTwilioPlugin.h"
#import <flutter_twilio/flutter_twilio-Swift.h>

@implementation FlutterTwilioPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterTwilioPlugin registerWithRegistrar:registrar];
}
@end
