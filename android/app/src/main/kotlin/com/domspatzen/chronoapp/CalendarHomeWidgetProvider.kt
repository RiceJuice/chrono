package com.domspatzen.chronoapp

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class CalendarHomeWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetIds: IntArray,
    widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val options = appWidgetManager.getAppWidgetOptions(widgetId)
      updateWidget(context, appWidgetManager, widgetId, widgetData, options)
    }
  }

  override fun onAppWidgetOptionsChanged(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    newOptions: Bundle,
  ) {
    val widgetData = HomeWidgetPlugin.getData(context)
    updateWidget(context, appWidgetManager, appWidgetId, widgetData, newOptions)
    super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
  }

  private fun resolveWidgetSizeDp(options: Bundle?): Pair<Int, Int> {
    val minWidth = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) ?: 250
    val minHeight = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT) ?: 110
    val maxWidth = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH) ?: minWidth
    val maxHeight = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT) ?: minHeight
    return Pair(maxOf(minWidth, maxWidth), maxOf(minHeight, maxHeight))
  }

  private fun updateWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    widgetId: Int,
    widgetData: SharedPreferences,
    options: Bundle?,
  ) {
    val (widthDp, heightDp) = resolveWidgetSizeDp(options)
    val density = context.resources.displayMetrics.density

    widgetData
      .edit()
      .putInt("calendar_widget_height_dp", heightDp)
      .putInt("calendar_widget_width_dp", widthDp)
      .putFloat("calendar_widget_density", density)
      .apply()

    val isDark =
      (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
        Configuration.UI_MODE_NIGHT_YES
    val themeSuffix = if (isDark) "dark" else "light"

    val imageKeys =
      listOf(
        "calendar_widget_android_$themeSuffix",
        if (heightDp >= 200) {
          "calendar_widget_large_$themeSuffix"
        } else {
          "calendar_widget_medium_$themeSuffix"
        },
      )

    val imagePath =
      imageKeys.firstNotNullOfOrNull { key -> widgetData.getString(key, null) }

    val views =
      RemoteViews(context.packageName, R.layout.calendar_home_widget).apply {
        val pendingIntent =
          HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("chronoapp://calendar"),
          )
        setOnClickPendingIntent(R.id.calendar_widget_container, pendingIntent)

        if (imagePath != null) {
          val bitmap = BitmapFactory.decodeFile(imagePath)
          if (bitmap != null) {
            setImageViewBitmap(R.id.calendar_widget_image, bitmap)
            setViewVisibility(R.id.calendar_widget_image, View.VISIBLE)
            setViewVisibility(R.id.calendar_widget_placeholder, View.GONE)
          } else {
            setViewVisibility(R.id.calendar_widget_image, View.GONE)
            setViewVisibility(R.id.calendar_widget_placeholder, View.VISIBLE)
          }
        } else {
          setViewVisibility(R.id.calendar_widget_image, View.GONE)
          setViewVisibility(R.id.calendar_widget_placeholder, View.VISIBLE)
        }
      }

    appWidgetManager.updateAppWidget(widgetId, views)
  }
}
