package app.moment.moment.widget

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.updateAll

object MomentWidgetUpdater {
    suspend fun update(context: Context) {
        WidgetTimeRefresh.schedule(context)
        MomentGlanceWidget().updateAll(context)
    }
}
