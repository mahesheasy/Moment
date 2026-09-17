package app.moment.moment.widget

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.ActionCallback

/** Marks a moment seen on the widget, refreshes Glance, then opens the app. */
class WidgetOpenMomentAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val momentId = parameters[MomentIdKey] ?: return
        if (momentId.isBlank()) return
        WidgetMomentQueue.markSeenOnWidget(context, momentId)
        MomentWidgetUpdater.updatePreservingView(context)
        context.startActivity(launchDeepLink(momentId))
    }

    companion object {
        val MomentIdKey = ActionParameters.Key<String>("moment_id")

        private fun launchDeepLink(momentId: String): Intent =
            Intent(Intent.ACTION_VIEW, Uri.parse("moment://moment/$momentId")).apply {
                setClassName("app.moment.moment", "app.moment.moment.MainActivity")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
    }
}
