package app.moment.moment.widget

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.updateAll
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

object MomentWidgetUpdater {
    suspend fun update(context: Context, resetPreview: Boolean = false) {
        if (resetPreview) {
            val momentId =
                WidgetMomentQueue.activeEntry(context)?.momentId
                    ?: MomentWidgetDataStore.load(context).momentId
            WidgetMediaPrivacyPreview.beginSession(context, momentId)
        }
        refresh(context)
    }

    suspend fun updateIncomingMoment(context: Context, momentId: String) {
        WidgetMediaPrivacyPreview.beginSession(context, momentId)
        refresh(context)
    }

    suspend fun updatePreservingView(context: Context) {
        refresh(context)
    }

    private suspend fun refresh(context: Context) {
        withContext(Dispatchers.Main.immediate) {
            runCatching { WidgetTimeRefresh.schedule(context) }
            runCatching { MomentGlanceWidget().updateAll(context) }
        }
    }
}
