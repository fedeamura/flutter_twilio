package com.dormmom.flutter_twilio_voice;

import android.app.Application;
import android.util.Log;

import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleObserver;
import androidx.lifecycle.OnLifecycleEvent;
import androidx.lifecycle.ProcessLifecycleOwner;

public class App extends Application implements LifecycleObserver {

    static boolean visible;

    @Override
    public void onCreate() {
        super.onCreate();
        visible = true;
        Log.i("App", "ON_CREATE");
        ProcessLifecycleOwner.get().getLifecycle().addObserver(this);
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_STOP)
    public void onAppBackgrounded() {
        Log.i("App", "ON_STOP");
        visible = false;
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_START)
    public void onAppForegrounded() {
        Log.i("App", "ON_START");
        visible = true;
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_RESUME)
    public void onAppResume() {
        Log.i("App", "ON_RESUME");
        visible = true;
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_DESTROY)
    public void onAppDestroy() {
        Log.i("App", "ON_DESTROY");
        visible = false;
    }


}
