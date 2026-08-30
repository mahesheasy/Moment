package app.moment.moment.widget

import android.content.Context
import android.content.Intent
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class MomentWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = MomentGlanceWidget()

    override fun onReceive(context: Context, intent: Intent) {
        val appContext = context.applicationContext
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                WidgetTimeRefresh.schedule(appContext)
                WidgetSyncScheduler.schedulePeriodic(appContext)
            }
            Intent.ACTION_SCREEN_OFF -> {
                WidgetMediaPrivacyPreview.protectImmediately(appContext)
                widgetScope.launch { MomentWidgetUpdater.updatePreservingView(appContext) }
                return
            }
            Intent.ACTION_SCREEN_ON -> {
                val data = MomentWidgetDataStore.load(appContext)
                if (data.hasMoment && data.momentId.isNotBlank()) {
                    WidgetMediaPrivacyPreview.beginSession(appContext, data.momentId)
                }
                widgetScope.launch { MomentWidgetUpdater.updatePreservingView(appContext) }
                return
            }
        }
        super.onReceive(context, intent)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        val appContext = context.applicationContext
        runCatching { WidgetTimeRefresh.schedule(appContext) }
        widgetScope.launch {
            delay(800)
            if (WidgetMomentQueue.loadQueue(appContext).isNotEmpty()) {
                MomentWidgetUpdater.updatePreservingView(appContext)
            }
        }
    }

    override fun onDisabled(context: Context) {
        WidgetTimeRefresh.cancel(context.applicationContext)
        WidgetMediaPrivacyPreview.cancelSession(context.applicationContext)
        super.onDisabled(context)
    }

    companion object {
        private val widgetScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    }
}
