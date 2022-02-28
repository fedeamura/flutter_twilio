package com.dormmom.flutter_twilio_voice.Utils;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

import java.util.Map;

public class PreferencesUtils {
    private static final String TAG = "PreferencesUtils";

    private SharedPreferences sharedPreferencesAccess;
    private SharedPreferences sharedPreferencesContactData;
    private static PreferencesUtils instance;

    private PreferencesUtils() {

    }

    public static PreferencesUtils getInstance(Context context) {
        if (instance == null) {
            instance = new PreferencesUtils();
            instance.sharedPreferencesAccess = context.getSharedPreferences(TwilioConstants.SHARED_PREFERENCES_ACCESS, Context.MODE_PRIVATE);
            instance.sharedPreferencesContactData = context.getSharedPreferences(TwilioConstants.SHARED_PREFERENCES_CONTACT_DATA, Context.MODE_PRIVATE);
        }
        return instance;
    }


    public void setContacts(Map<String, Object> data, String defaultDisplayName) {
        SharedPreferences.Editor editor = this.sharedPreferencesContactData.edit();

        // Save default display name
        if (defaultDisplayName == null) defaultDisplayName = "";
        editor.putString(TwilioConstants.SHARED_PREFERENCES_KEY_DEFAULT_DISPLAY_NAME, defaultDisplayName);

        // Save contacts
        if (data != null) {
            int i = 0;
            for (Map.Entry<String, Object> keyValue : data.entrySet()) {
                //noinspection unchecked
                Map<String, Object> item = (Map<String, Object>) keyValue.getValue();
                String phoneNumber = keyValue.getKey();
                String displayName = (String) item.get("displayName");
                if (displayName == null) displayName = "";
                String photoURL = (String) item.get("photoURL");
                if (photoURL == null) photoURL = "";
                editor.putString(phoneNumber, displayName + ";" + photoURL);
                i++;
            }
            Log.i(TAG, "Saved " + i + " contacts");
        }

        editor.apply();
    }

    public String findContactName(String phoneNumber) {
        String defaultDisplayName = this.getDefaultDisplayName();

        if (phoneNumber == null || phoneNumber.trim().equals("")) {
            Log.i(TAG, "Error finding the contact display. No phone number");
            return defaultDisplayName;
        }

        final String value = this.sharedPreferencesContactData.getString(phoneNumber, null);
        if (value == null || value.equals("")) {
            Log.i(TAG, "Error finding the contact display name for " + phoneNumber + ". No value stored");
            return defaultDisplayName;
        }

        try {
            final String[] parts = value.split(";");
            if (parts.length == 0) {
                Log.i(TAG, "Error finding the contact display name for " + phoneNumber + ". The stored value is wrong " + value + ". Contains " + parts.length + " parts.");
                return defaultDisplayName;
            }

            return parts[0];
        } catch (Exception e) {
            Log.i(TAG, "Error finding the contact display name for " + phoneNumber + ". Error: " + e.getMessage());
            return defaultDisplayName;
        }
    }

    public String findPhotoURL(String phoneNumber) {
        if (phoneNumber == null || phoneNumber.trim().equals("")) {
            Log.i(TAG, "Error finding the contact photo URL. No phone number");
            return "";
        }

        final String value = this.sharedPreferencesContactData.getString(phoneNumber, null);
        if (value == null || value.equals("")) {
            Log.i(TAG, "Error finding the contact photo URL name for " + phoneNumber + ". No value stored");
            return "";
        }

        try {
            final String[] parts = value.split(";");
            if (parts.length < 2) {
                Log.i(TAG, "Error finding the contact photo URL name for " + phoneNumber + ". The stored value is wrong " + value + ". Contains " + parts.length + " parts.");
                return "";
            }
            return parts[1];
        } catch (Exception e) {
            Log.i(TAG, "Error finding the contact photo URL name for " + phoneNumber + ". Error: " + e.getMessage());
            return "";
        }
    }

    public String getDefaultDisplayName() {
        String value = this.sharedPreferencesContactData.getString(TwilioConstants.SHARED_PREFERENCES_KEY_DEFAULT_DISPLAY_NAME, "");
        if (value == null || value.equals("")) return "";
        return value;
    }

    public void storeAccess(String identity, String accessToken, String fcmToken) {
        SharedPreferences.Editor editor = this.sharedPreferencesAccess.edit();
        editor.putString(TwilioConstants.SHARED_PREFERENCES_KEY_IDENTITY, identity);
        editor.putString(TwilioConstants.SHARED_PREFERENCES_KEY_ACCESS_TOKEN, accessToken);
        editor.putString(TwilioConstants.SHARED_PREFERENCES_KEY_FCM_TOKEN, fcmToken);
        editor.apply();
    }

    public void clearAccess() {
        this.sharedPreferencesAccess.edit().clear().apply();
    }

    public String getAccessToken() {
        return this.sharedPreferencesAccess.getString(TwilioConstants.SHARED_PREFERENCES_KEY_ACCESS_TOKEN, null);
    }

    public String getFcmToken() {
        return this.sharedPreferencesAccess.getString(TwilioConstants.SHARED_PREFERENCES_KEY_FCM_TOKEN, null);
    }
}
