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
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            WidgetTimeRefresh.schedule(context.applicationContext)
            WidgetSyncScheduler.schedulePeriodic(context.applicationContext)
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
        super.onDisabled(context)
    }

    companion object {
        private val widgetScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    }
}
