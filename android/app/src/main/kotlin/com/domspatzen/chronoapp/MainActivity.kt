package com.domspatzen.chronoapp

import com.istornz.live_activities.LiveActivityManagerHolder
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        LiveActivityManagerHolder.instance = ChronoLiveActivityManager(this)
    }
}
