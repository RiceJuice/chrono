package com.domspatzen.chronoapp

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.istornz.live_activities.LiveActivityManager
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit
import kotlin.math.max
import kotlin.math.min

class ChronoLiveActivityManager(context: Context) : LiveActivityManager(context) {
    private val appContext: Context = context.applicationContext
    private val remoteViews = RemoteViews(appContext.packageName, R.layout.live_activity)
    private val timeFormat = SimpleDateFormat("HH:mm", Locale.GERMANY)

    private val pendingIntent = PendingIntent.getActivity(
        appContext,
        200,
        Intent(appContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
        },
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun updateRemoteViews(data: Map<String, Any>) {
        val currentTitle = data["currentTitle"] as? String ?: ""
        val currentSubtitle = data["currentSubtitle"] as? String ?: ""
        val nextTitle = data["nextTitle"] as? String ?: ""
        val nextSubtitle = data["nextSubtitle"] as? String ?: ""
        val startMs = (data["segmentStartMs"] as? Number)?.toLong() ?: 0L
        val endMs = (data["segmentEndMs"] as? Number)?.toLong() ?: 0L
        val now = System.currentTimeMillis()

        remoteViews.setTextViewText(R.id.current_title, currentTitle)
        remoteViews.setTextViewText(R.id.current_subtitle, currentSubtitle)
        remoteViews.setTextViewText(R.id.next_title, nextTitle)
        remoteViews.setTextViewText(R.id.next_subtitle, nextSubtitle)
        remoteViews.setTextViewText(R.id.segment_start, timeFormat.format(Date(startMs)))
        remoteViews.setTextViewText(R.id.segment_end, timeFormat.format(Date(endMs)))

        val remainingMinutes = max(
            0,
            TimeUnit.MILLISECONDS.toMinutes(endMs - now).toInt() +
                if ((endMs - now) % 60_000L > 0) 1 else 0,
        )
        remoteViews.setTextViewText(
            R.id.remaining_label,
            "Noch $remainingMinutes Min.",
        )

        val progress = if (endMs <= startMs) {
            1000
        } else {
            val ratio = (now - startMs).toDouble() / (endMs - startMs).toDouble()
            (min(1.0, max(0.0, ratio)) * 1000).toInt()
        }
        remoteViews.setProgressBar(R.id.segment_progress, 1000, progress, false)
    }

    override suspend fun buildNotification(
        notification: Notification.Builder,
        event: String,
        data: Map<String, Any>,
    ): Notification {
        updateRemoteViews(data)
        val currentTitle = data["currentTitle"] as? String ?: "Ablaufplan"
        return notification
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setContentTitle(currentTitle)
            .setContentIntent(pendingIntent)
            .setStyle(Notification.DecoratedCustomViewStyle())
            .setCustomContentView(remoteViews)
            .setCustomBigContentView(remoteViews)
            .setPriority(Notification.PRIORITY_LOW)
            .setCategory(Notification.CATEGORY_EVENT)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .build()
    }
}
