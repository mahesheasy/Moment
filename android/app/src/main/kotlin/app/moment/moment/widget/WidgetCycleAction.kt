package app.moment.moment.widget

import android.content.Context
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.action.ActionCallback

class WidgetCycleAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val delta = parameters[DeltaKey] ?: 1
        WidgetMomentQueue.cycle(context, delta)
        val activeMomentId = MomentWidgetDataStore.load(context).momentId
        val manager = GlanceAppWidgetManager(context)
        val ids = manager.getGlanceIds(MomentGlanceWidget::class.java)
        ids.forEach { id ->
            MomentGlanceWidget().update(context, id)
        }
    }

    companion object {
        val DeltaKey = ActionParameters.Key<Int>("delta")
    }
}
