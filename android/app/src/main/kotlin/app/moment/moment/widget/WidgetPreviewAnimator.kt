package app.moment.moment.widget

import android.content.Context
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

object WidgetPreviewAnimator {
    private const val TICK_MS = 250L
    private const val MAX_TICKS = 24

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var activeJob: kotlinx.coroutines.Job? = null

    fun scheduleUiRefreshes(context: Context) {
        cancel()
        val appContext = context.applicationContext
        activeJob =
            scope.launch {
                repeat(MAX_TICKS) {
                    if (!WidgetMediaPrivacyPreview.isSessionActive(appContext)) return@launch
                    MomentWidgetUpdater.updatePreservingView(appContext)
                    delay(TICK_MS)
                }
            }
    }

    fun cancel() {
        activeJob?.cancel()
        activeJob = null
    }
}
