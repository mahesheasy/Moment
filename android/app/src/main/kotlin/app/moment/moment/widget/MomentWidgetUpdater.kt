package app.moment.moment.widget

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.updateAll
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

object MomentWidgetUpdater {
    suspend fun update(context: Context, resetPreview: Boolean = false) {
        refresh(context)
    }

    suspend fun updateIncomingMoment(context: Context, momentId: String) {
        refresh(context)
        WidgetRenderLatency.onMetadataRendered(momentId)
        val entry = WidgetMomentQueue.findEntry(context, momentId)
        if (!entry?.imagePath.isNullOrBlank()) {
            WidgetRenderLatency.onPhotoRendered(momentId)
        }
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
