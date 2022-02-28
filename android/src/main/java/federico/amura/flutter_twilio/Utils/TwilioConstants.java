package federico.amura.flutter_twilio.Utils;

public class TwilioConstants {
    public static final int NOTIFICATION_INCOMING_CALL = 1;
    public static final int NOTIFICATION_MISSED_CALL = 2;

    public static final String CALL_SID_KEY = "CALL_SID";
    public static final String SHARED_PREFERENCES_ACCESS = "access";
    public static final String SHARED_PREFERENCES_CONTACT_DATA = "contact_data";

    public static final String SHARED_PREFERENCES_KEY_ACCESS_TOKEN = "access_token";
    public static final String SHARED_PREFERENCES_KEY_IDENTITY = "identity";
    public static final String SHARED_PREFERENCES_KEY_FCM_TOKEN = "fcm_token";
    public static final String SHARED_PREFERENCES_KEY_DEFAULT_DISPLAY_NAME = "default_display_name";

    public static final String VOICE_CHANNEL_LOW_IMPORTANCE = "notification-channel-low-importance";
    public static final String VOICE_CHANNEL_HIGH_IMPORTANCE = "notification-channel-high-importance";

    public static final String EXTRA_INCOMING_CALL_INVITE = "EXTRA_INCOMING_CALL_INVITE";
    public static final String EXTRA_CANCELLED_CALL_INVITE = "EXTRA_CANCELLED_CALL_INVITE";
    public static final String EXTRA_CALL_TO = "EXTRA_CALL_TO";

    public static final String ACTION_ACCEPT = "ACTION_ACCEPT";
    public static final String ACTION_REJECT = "ACTION_REJECT";
    public static final String ACTION_INCOMING_CALL = "ACTION_INCOMING_CALL";
    public static final String ACTION_CANCEL_CALL = "ACTION_CANCEL_CALL";
    public static final String ACTION_STOP_SERVICE = "ACTION_STOP_SERVICE";
}
