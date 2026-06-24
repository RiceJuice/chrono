package com.domspatzen.chronoapp

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import com.istornz.live_activities.LiveActivityManager
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.max
import kotlin.math.min

class ChronoLiveActivityManager(context: Context) : LiveActivityManager(context) {
    private val appContext: Context = context.applicationContext
    private val collapsedViews =
        RemoteViews(appContext.packageName, R.layout.live_activity)
    private val expandedViews =
        RemoteViews(appContext.packageName, R.layout.live_activity_expanded)
    private val timeFormat = SimpleDateFormat("HH:mm", Locale.GERMANY)

    private fun pendingIntentFor(eventId: String): PendingIntent {
        val intent = Intent(appContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP
            if (eventId.isNotEmpty()) {
                data = Uri.parse(
                    "chronoapp://schedule?eventId=${Uri.encode(eventId)}",
                )
            }
        }
        return PendingIntent.getActivity(
            appContext,
            eventId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun setTextOrHide(views: RemoteViews, viewId: Int, text: String) {
        if (text.isBlank()) {
            views.setViewVisibility(viewId, View.GONE)
        } else {
            views.setViewVisibility(viewId, View.VISIBLE)
            views.setTextViewText(viewId, text)
        }
    }

    private fun color(resId: Int): Int =
        ContextCompat.getColor(appContext, resId)

    private fun applyThemeColors(views: RemoteViews, expanded: Boolean) {
        val primary = color(R.color.live_activity_text_primary)
        val secondary = color(R.color.live_activity_text_secondary)
        val arrow = color(R.color.live_activity_arrow)

        views.setTextColor(R.id.current_title, primary)
        views.setTextColor(R.id.arrow_icon, arrow)
        views.setTextColor(R.id.next_title, primary)
        views.setTextColor(R.id.remaining_chronometer, primary)

        if (!expanded) return

        views.setTextColor(R.id.current_subtitle, secondary)
        views.setTextColor(R.id.next_subtitle, secondary)
        views.setTextColor(R.id.segment_start, secondary)
        views.setTextColor(R.id.segment_end, secondary)
        views.setInt(
            R.id.segment_progress,
            "setProgressDrawable",
            R.drawable.live_activity_progress,
        )
    }

    private fun applyCountdownChronometer(views: RemoteViews, endMs: Long) {
        val now = System.currentTimeMillis()
        val remainingMs = max(0L, endMs - now)
        val base = SystemClock.elapsedRealtime() + remainingMs

        views.setChronometerCountDown(R.id.remaining_chronometer, true)
        views.setChronometer(R.id.remaining_chronometer, base, "Noch %s", true)
        views.setViewVisibility(R.id.remaining_chronometer, View.VISIBLE)
    }

    private fun updateRemoteViews(views: RemoteViews, data: Map<String, Any>, expanded: Boolean) {
        applyThemeColors(views, expanded)
        val currentTitle = data["currentTitle"] as? String ?: ""
        val currentSubtitle = data["currentSubtitle"] as? String ?: ""
        val nextTitle = data["nextTitle"] as? String ?: ""
        val nextSubtitle = data["nextSubtitle"] as? String ?: ""
        val startMs = (data["segmentStartMs"] as? Number)?.toLong() ?: 0L
        val endMs = (data["segmentEndMs"] as? Number)?.toLong() ?: 0L
        val now = System.currentTimeMillis()
        val hasNext = nextTitle.isNotBlank()

        views.setTextViewText(R.id.current_title, currentTitle)
        applyCountdownChronometer(views, endMs)

        if (hasNext) {
            views.setViewVisibility(R.id.arrow_icon, View.VISIBLE)
            views.setViewVisibility(R.id.next_title, View.VISIBLE)
            views.setTextViewText(R.id.next_title, nextTitle)
        } else {
            views.setViewVisibility(R.id.arrow_icon, View.GONE)
            views.setViewVisibility(R.id.next_title, View.GONE)
        }

        if (!expanded) return

        setTextOrHide(views, R.id.current_subtitle, currentSubtitle)

        if (hasNext) {
            views.setViewVisibility(R.id.next_column, View.VISIBLE)
            setTextOrHide(views, R.id.next_subtitle, nextSubtitle)
        } else {
            views.setViewVisibility(R.id.next_column, View.GONE)
        }

        views.setTextViewText(R.id.segment_start, timeFormat.format(Date(startMs)))
        views.setTextViewText(R.id.segment_end, timeFormat.format(Date(endMs)))

        val progress = if (endMs <= startMs) {
            1000
        } else {
            val ratio = (now - startMs).toDouble() / (endMs - startMs).toDouble()
            (min(1.0, max(0.0, ratio)) * 1000).toInt()
        }
        views.setProgressBar(R.id.segment_progress, 1000, progress, false)
    }

    override suspend fun buildNotification(
        notification: Notification.Builder,
        event: String,
        data: Map<String, Any>,
    ): Notification {
        updateRemoteViews(collapsedViews, data, expanded = false)
        updateRemoteViews(expandedViews, data, expanded = true)

        val eventId = data["eventId"] as? String ?: ""
        return notification
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setShowWhen(false)
            .setContentIntent(pendingIntentFor(eventId))
            .setCustomContentView(collapsedViews)
            .setCustomBigContentView(expandedViews)
            .setPriority(Notification.PRIORITY_LOW)
            .setCategory(Notification.CATEGORY_EVENT)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .build()
    }
}
