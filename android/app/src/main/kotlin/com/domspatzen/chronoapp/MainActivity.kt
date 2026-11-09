package com.domspatzen.chronoapp

import com.istornz.live_activities.LiveActivityManagerHolder
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.DatePickerDialog
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "chrono/homework_date")
            .setMethodCallHandler { call, result ->
                if (call.method != "pickDate") {
                    result.notImplemented()
                } else {
                    val format = SimpleDateFormat("yyyy-MM-dd", Locale.US)
                    val initial = Calendar.getInstance().apply {
                        time = format.parse(call.argument<String>("initial")!!)!!
                    }
                    val dialog = DatePickerDialog(this, { _, year, month, day ->
                        val picked = Calendar.getInstance().apply { set(year, month, day) }
                        result.success(format.format(picked.time))
                    }, initial.get(Calendar.YEAR), initial.get(Calendar.MONTH),
                        initial.get(Calendar.DAY_OF_MONTH))
                    dialog.datePicker.minDate = format.parse(call.argument<String>("minimum")!!)!!.time
                    dialog.datePicker.maxDate = format.parse(call.argument<String>("maximum")!!)!!.time
                    dialog.setOnCancelListener { result.success(null) }
                    dialog.show()
                }
            }
        LiveActivityManagerHolder.instance = ChronoLiveActivityManager(this)
    }
}
