package app.moment.moment.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/** Arms a one-shot clear widget frame after the user unlocks their phone. */
class WidgetUserPresentReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_USER_PRESENT) return
        val appContext = context.applicationContext
        val entry = WidgetMomentQueue.activeEntry(appContext) ?: return
        val widgetData = MomentWidgetDataStore.load(appContext)
        if (!widgetData.lockScreenPrivacy) return
        if (widgetData.paused) return
        if (WidgetPrivacyResolver.resolvePrivacyForSender(appContext, entry.senderId) != "full") {
            return
        }

        val age = System.currentTimeMillis() - entry.createdAtMillis
        if (age < 0 || age > WidgetUnlockReveal.RECENT_MOMENT_WINDOW_MS) return

        WidgetUnlockReveal.arm(appContext, entry.momentId)
        scope.launch {
            MomentWidgetUpdater.updatePreservingView(appContext)
            delay(WidgetUnlockReveal.CLEAR_FRAME_REVERT_MS)
            WidgetUnlockReveal.clear(appContext)
            MomentWidgetUpdater.updatePreservingView(appContext)
        }
    }

    companion object {
        private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    }
}
