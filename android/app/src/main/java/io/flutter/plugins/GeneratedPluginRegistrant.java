package io.flutter.plugins;

import io.flutter.plugin.common.PluginRegistry;

import federico.amura.flutter_twilio.FlutterTwilioPlugin;

/**
 * Generated file. Do not edit.
 */
public final class GeneratedPluginRegistrant {
    public static void registerWith(PluginRegistry registry) {
        if (alreadyRegisteredWith(registry)) {
            return;
        }
        FlutterTwilioPlugin.registerWith(registry.registrarFor("federico.amura.flutter_twilio.FlutterTwilioPlugin"));
    }

    private static boolean alreadyRegisteredWith(PluginRegistry registry) {
        final String key = GeneratedPluginRegistrant.class.getCanonicalName();
        if (registry.hasPlugin(key)) {
            return true;
        }
        registry.registrarFor(key);
        return false;
    }
}
