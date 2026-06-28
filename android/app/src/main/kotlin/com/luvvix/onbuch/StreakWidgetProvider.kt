package com.luvvix.onbuch

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget d'écran d'accueil « Ma série » (streak OnBuch).
 * Les données sont poussées depuis Flutter via le package home_widget
 * (clés : streak, streak_done_today). Un tap ouvre l'application.
 */
class StreakWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val streak = widgetData.getInt("streak", 0)
        val doneToday = widgetData.getBoolean("streak_done_today", false)

        val sub = when {
            streak <= 0 -> "Lance ta série 🔥"
            doneToday -> "Validée aujourd'hui ✅"
            else -> "Reviens réviser 💪"
        }

        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.streak_widget).apply {
                setTextViewText(R.id.streak_count, streak.toString())
                setTextViewText(R.id.streak_unit, if (streak == 1) "jour" else "jours")
                setTextViewText(R.id.streak_sub, sub)

                // Tap sur le widget → ouvre l'application.
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.streak_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
