package com.domspatzen.chronoapp

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import com.istornz.live_activities.LiveActivityManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.math.BigInteger
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.max
import kotlin.math.min

class ChronoLiveActivityManager(context: Context) : LiveActivityManager(context) {
    private companion object {
        private const val NOTIFICATION_CHANNEL_NAME = "Live Activities"
    }

    private val appContext: Context = context.applicationContext
    private val collapsedViews =
        RemoteViews(appContext.packageName, R.layout.live_activity)
    private val expandedViews =
        RemoteViews(appContext.packageName, R.layout.live_activity_expanded)
    private val timeFormat = SimpleDateFormat("HH:mm", Locale.GERMANY)

    private var cachedMealImageUrl: String? = null
    private var cachedMealBitmap: Bitmap? = null

    private data class TimetableSegment(
        val id: String,
        val type: String,
        val title: String,
        val shortTitle: String?,
        val subtitle: String,
        val startMs: Long,
        val endMs: Long,
        val accentColor: String,
        val imageUrl: String?,
    ) {
        fun displayShortTitle(): String {
            val trimmed = shortTitle?.trim().orEmpty()
            if (trimmed.isNotEmpty()) return trimmed
            val titleTrimmed = title.trim()
            if (titleTrimmed.length <= 3) return titleTrimmed
            return titleTrimmed.take(3)
        }
    }

    private data class ResolvedSegment(
        val title: String,
        val subtitle: String,
        val shortTitle: String,
        val segmentStartMs: Long,
        val segmentEndMs: Long,
        val hasNext: Boolean,
        val nextTitle: String,
        val nextSubtitle: String,
        val nextShortTitle: String,
        val remainingLessons: Int,
        val isMeal: Boolean,
        val imageUrl: String?,
        val isPreStart: Boolean,
    )

    private fun pendingIntentForSchedule(eventId: String): PendingIntent {
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

    private fun pendingIntentForTimetable(dayDate: String): PendingIntent {
        val intent = Intent(appContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP
            if (dayDate.isNotEmpty()) {
                data = Uri.parse(
                    "chronoapp://timetable?date=${Uri.encode(dayDate)}",
                )
            }
        }
        return PendingIntent.getActivity(
            appContext,
            dayDate.hashCode(),
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

    private fun parseSegments(rawJson: String?): List<TimetableSegment> {
        if (rawJson.isNullOrBlank()) return emptyList()
        return try {
            val array = JSONArray(rawJson)
            buildList {
                for (i in 0 until array.length()) {
                    val obj = array.optJSONObject(i) ?: continue
                    add(
                        TimetableSegment(
                            id = obj.optString("id"),
                            type = obj.optString("type"),
                            title = obj.optString("title"),
                            shortTitle = obj.optString("shortTitle").ifBlank { null },
                            subtitle = obj.optString("subtitle"),
                            startMs = obj.optLong("startMs"),
                            endMs = obj.optLong("endMs"),
                            accentColor = obj.optString("accentColor", "#124E30"),
                            imageUrl = obj.optString("imageUrl").ifBlank { null },
                        ),
                    )
                }
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun resolveTimetable(
        segments: List<TimetableSegment>,
        activityStartMs: Long,
        nowMs: Long,
    ): ResolvedSegment? {
        if (segments.isEmpty()) return null

        segments.forEachIndexed { index, segment ->
            if (nowMs < segment.startMs) {
                val gapStart = if (index > 0) segments[index - 1].endMs else activityStartMs
                val next = segments.getOrNull(index + 1)
                return ResolvedSegment(
                    title = segment.title,
                    subtitle = segment.subtitle,
                    shortTitle = segment.displayShortTitle(),
                    segmentStartMs = gapStart,
                    segmentEndMs = segment.startMs,
                    hasNext = next != null,
                    nextTitle = next?.title ?: "",
                    nextSubtitle = next?.subtitle ?: "",
                    nextShortTitle = next?.displayShortTitle() ?: "",
                    remainingLessons = remainingLessonCount(segments, index, isPreStart = true),
                    isMeal = segment.type == "meal",
                    imageUrl = segment.imageUrl,
                    isPreStart = true,
                )
            }
            if (nowMs < segment.endMs) {
                val next = segments.getOrNull(index + 1)
                return ResolvedSegment(
                    title = segment.title,
                    subtitle = segment.subtitle,
                    shortTitle = segment.displayShortTitle(),
                    segmentStartMs = segment.startMs,
                    segmentEndMs = segment.endMs,
                    hasNext = next != null,
                    nextTitle = next?.title ?: "",
                    nextSubtitle = next?.subtitle ?: "",
                    nextShortTitle = next?.displayShortTitle() ?: "",
                    remainingLessons = remainingLessonCount(segments, index, isPreStart = false),
                    isMeal = segment.type == "meal",
                    imageUrl = segment.imageUrl,
                    isPreStart = false,
                )
            }
        }
        return null
    }

    private fun remainingLessonCount(
        segments: List<TimetableSegment>,
        fromIndex: Int,
        isPreStart: Boolean,
    ): Int {
        var count = 0
        for (i in fromIndex until segments.size) {
            val segment = segments[i]
            if (segment.type != "lesson") continue
            if (i == fromIndex && !isPreStart) continue
            count++
        }
        return count
    }

    private fun remainingLessonsLabel(count: Int): String {
        return if (count == 1) "Noch 1 Stunde" else "Noch $count Stunden"
    }

    private fun compactLeadingLabel(resolved: ResolvedSegment): String {
        return resolved.shortTitle.ifBlank { "—" }
    }

    private suspend fun loadMealImageBitmap(imageUrl: String?): Bitmap? {
        val dp = appContext.resources.displayMetrics.density
        return withContext(Dispatchers.IO) {
            if (imageUrl.isNullOrBlank()) return@withContext null
            try {
                val connection = URL(imageUrl).openConnection() as HttpURLConnection
                connection.doInput = true
                connection.connectTimeout = 4000
                connection.readTimeout = 4000
                connection.connect()
                connection.inputStream.use { inputStream ->
                    val original = BitmapFactory.decodeStream(inputStream) ?: return@withContext null
                    val targetSize = (72 * dp).toInt().coerceAtLeast(1)
                    val aspectRatio = original.width.toFloat() / original.height.toFloat()
                    val (targetWidth, targetHeight) = if (aspectRatio >= 1f) {
                        targetSize to (targetSize / aspectRatio).toInt().coerceAtLeast(1)
                    } else {
                        (targetSize * aspectRatio).toInt().coerceAtLeast(1) to targetSize
                    }
                    Bitmap.createScaledBitmap(original, targetWidth, targetHeight, true)
                }
            } catch (_: Exception) {
                null
            }
        }
    }

    private suspend fun ensureMealBitmap(imageUrl: String?): Bitmap? {
        if (imageUrl.isNullOrBlank()) {
            cachedMealImageUrl = null
            cachedMealBitmap = null
            return null
        }
        if (imageUrl == cachedMealImageUrl) {
            return cachedMealBitmap
        }
        val bitmap = loadMealImageBitmap(imageUrl)
        cachedMealImageUrl = imageUrl
        cachedMealBitmap = bitmap
        return bitmap
    }

    private fun applyMealImage(views: RemoteViews, bitmap: Bitmap?) {
        if (bitmap == null) {
            views.setViewVisibility(R.id.meal_image, View.GONE)
            return
        }
        views.setViewVisibility(R.id.meal_image, View.VISIBLE)
        views.setImageViewBitmap(R.id.meal_image, bitmap)
    }

    private fun hideMealImage(views: RemoteViews) {
        views.setViewVisibility(R.id.meal_image, View.GONE)
    }

    private fun activityIdFromData(data: Map<String, Any>): String? {
        val kind = data["kind"] as? String ?: "schedule"
        return when (kind) {
            "timetable" -> {
                val dayDate = data["dayDate"] as? String ?: return null
                "timetable_$dayDate"
            }
            else -> {
                val eventId = data["eventId"] as? String ?: return null
                "event_$eventId"
            }
        }
    }

    private fun notificationIdFromActivityId(activityId: String): Int {
        val digest = MessageDigest.getInstance("SHA-256").digest(activityId.toByteArray())
        return BigInteger(digest).abs().toInt()
    }

    private fun contentIntentFor(data: Map<String, Any>): PendingIntent {
        val kind = data["kind"] as? String ?: "schedule"
        return if (kind == "timetable") {
            val dayDate = data["dayDate"] as? String ?: ""
            pendingIntentForTimetable(dayDate)
        } else {
            val eventId = data["eventId"] as? String ?: ""
            pendingIntentForSchedule(eventId)
        }
    }

    private fun buildLiveActivityNotification(
        data: Map<String, Any>,
        timestamp: Long,
    ): Notification {
        updateRemoteViews(collapsedViews, data, expanded = false)
        updateRemoteViews(expandedViews, data, expanded = true)

        return Notification.Builder(appContext, NOTIFICATION_CHANNEL_NAME)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setShowWhen(false)
            .setContentIntent(contentIntentFor(data))
            .setCustomContentView(collapsedViews)
            .setCustomBigContentView(expandedViews)
            .setPriority(Notification.PRIORITY_LOW)
            .setCategory(Notification.CATEGORY_EVENT)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOnlyAlertOnce(true)
            .apply {
                extras.putLong("activity_timestamp", timestamp)
            }
            .build()
    }

    private fun updateRemoteViews(views: RemoteViews, data: Map<String, Any>, expanded: Boolean) {
        applyThemeColors(views, expanded)
        val kind = data["kind"] as? String ?: "schedule"
        val now = System.currentTimeMillis()

        val currentTitle = data["currentTitle"] as? String ?: ""
        val currentSubtitle = data["currentSubtitle"] as? String ?: ""
        val nextTitle = data["nextTitle"] as? String ?: ""
        val nextSubtitle = data["nextSubtitle"] as? String ?: ""
        var startMs = (data["segmentStartMs"] as? Number)?.toLong() ?: 0L
        var endMs = (data["segmentEndMs"] as? Number)?.toLong() ?: 0L

        if (kind == "timetable" && (startMs <= 0L || endMs <= 0L)) {
            val segments = parseSegments(data["segmentsJson"] as? String)
            val activityStartMs = (data["activityStartMs"] as? Number)?.toLong()
                ?: segments.firstOrNull()?.startMs
                ?: now
            val resolved = resolveTimetable(segments, activityStartMs, now)
            if (resolved != null) {
                views.setTextViewText(
                    R.id.current_title,
                    if (expanded) resolved.title else compactLeadingLabel(resolved),
                )
                applyCountdownChronometer(views, resolved.segmentEndMs)
                applySegmentProgress(views, resolved.segmentStartMs, resolved.segmentEndMs, now)
                return
            }
        }

        val isMeal = data["isMeal"] as? Boolean ?: false
        val hasNext = (data["hasNext"] as? Boolean) ?: nextTitle.isNotBlank()
        val compactTitle = if (kind == "timetable" && !expanded) {
            compactLeadingLabel(
                ResolvedSegment(
                    title = currentTitle,
                    subtitle = currentSubtitle,
                    shortTitle = currentTitle.take(3),
                    segmentStartMs = startMs,
                    segmentEndMs = endMs,
                    hasNext = hasNext,
                    nextTitle = nextTitle,
                    nextSubtitle = nextSubtitle,
                    nextShortTitle = "",
                    remainingLessons = 0,
                    isMeal = isMeal,
                    imageUrl = null,
                    isPreStart = false,
                ),
            )
        } else {
            currentTitle
        }

        views.setTextViewText(R.id.current_title, compactTitle)
        applyCountdownChronometer(views, endMs)

        if (isMeal && expanded) {
            views.setViewVisibility(R.id.arrow_icon, View.GONE)
            views.setViewVisibility(R.id.next_column, View.GONE)
            views.setViewVisibility(R.id.next_title, View.GONE)
            views.setViewVisibility(R.id.next_subtitle, View.GONE)
            applyMealImage(views, cachedMealBitmap)
        } else {
            hideMealImage(views)
            if (hasNext) {
                views.setViewVisibility(R.id.arrow_icon, View.VISIBLE)
                views.setViewVisibility(R.id.next_title, View.VISIBLE)
                views.setTextViewText(R.id.next_title, nextTitle)
            } else {
                views.setViewVisibility(R.id.arrow_icon, View.GONE)
                views.setViewVisibility(R.id.next_title, View.GONE)
            }
        }

        if (!expanded) return

        setTextOrHide(views, R.id.current_subtitle, currentSubtitle)

        if (!isMeal && hasNext) {
            views.setViewVisibility(R.id.next_column, View.VISIBLE)
            setTextOrHide(views, R.id.next_subtitle, nextSubtitle)
        } else {
            views.setViewVisibility(R.id.next_column, View.GONE)
        }

        views.setTextViewText(R.id.segment_start, timeFormat.format(Date(startMs)))
        views.setTextViewText(R.id.segment_end, timeFormat.format(Date(endMs)))
        applySegmentProgress(views, startMs, endMs, now)
    }

    private fun applySegmentProgress(
        views: RemoteViews,
        startMs: Long,
        endMs: Long,
        now: Long,
    ) {
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
        val kind = data["kind"] as? String ?: "schedule"
        if (kind == "timetable") {
            val isMeal = data["isMeal"] as? Boolean ?: false
            val imageUrl = data["imageUrl"] as? String
            if (isMeal && !imageUrl.isNullOrBlank()) {
                ensureMealBitmap(imageUrl)
            } else {
                cachedMealImageUrl = null
                cachedMealBitmap = null
            }
        } else {
            cachedMealImageUrl = null
            cachedMealBitmap = null
        }

        return buildLiveActivityNotification(data, System.currentTimeMillis())
    }
}
