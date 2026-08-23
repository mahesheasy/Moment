package app.moment.moment.widget

import android.content.Context
import android.content.Intent
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver

class MomentWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = MomentGlanceWidget()

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            WidgetTimeRefresh.schedule(context)
        }
        super.onReceive(context, intent)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetTimeRefresh.schedule(context)
    }

    override fun onDisabled(context: Context) {
        WidgetTimeRefresh.cancel(context)
        super.onDisabled(context)
    }
}
