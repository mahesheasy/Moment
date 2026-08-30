package app.moment.moment.widget

import android.content.Context

/**
 * Per-view progressive blur for home-screen widget media.
 * CLEAR → 5s animated blur → fully blurred.
 */
object WidgetMediaPrivacyPreview {
    const val PREVIEW_DURATION_MS = 5_000L

    fun beginSession(
        context: Context,
        momentId: String? = null,
    ) {
        val activeMomentId =
            momentId?.takeIf { it.isNotBlank() }
                ?: WidgetMomentQueue.activeEntry(context)?.momentId
                ?: MomentWidgetDataStore.load(context).momentId
        if (activeMomentId.isBlank()) return

        val prefs = context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
        prefs.edit()
            .putLong(MomentWidgetDataStore.KEY_PREVIEW_STARTED_AT, System.currentTimeMillis())
            .putString(MomentWidgetDataStore.KEY_PREVIEW_MOMENT_ID, activeMomentId)
            .commit()
        WidgetPreviewAnimator.scheduleUiRefreshes(context)
    }

    fun protectImmediately(context: Context) {
        val prefs = context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
        prefs.edit()
            .putLong(
                MomentWidgetDataStore.KEY_PREVIEW_STARTED_AT,
                System.currentTimeMillis() - PREVIEW_DURATION_MS,
            )
            .commit()
        WidgetPreviewAnimator.cancel()
    }

    fun cancelSession(context: Context) {
        WidgetPreviewAnimator.cancel()
    }

    fun previewProgress(
        context: Context,
        momentId: String? = null,
    ): Float {
        val prefs = context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
        val sessionMomentId = prefs.getString(MomentWidgetDataStore.KEY_PREVIEW_MOMENT_ID, null)
        val activeMomentId = momentId?.takeIf { it.isNotBlank() } ?: sessionMomentId
        if (sessionMomentId.isNullOrBlank() || activeMomentId.isNullOrBlank()) {
            return 0f
        }
        if (sessionMomentId != activeMomentId) {
            return 0f
        }
        val startedAt = prefs.getLong(MomentWidgetDataStore.KEY_PREVIEW_STARTED_AT, 0L)
        if (startedAt <= 0L) return 0f
        val elapsed = System.currentTimeMillis() - startedAt
        if (elapsed >= PREVIEW_DURATION_MS) return 1f
        return (elapsed.toFloat() / PREVIEW_DURATION_MS).coerceIn(0f, 1f)
    }

    fun isSessionActive(context: Context): Boolean {
        return previewProgress(context) < 1f
    }
}
