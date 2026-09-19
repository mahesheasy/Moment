package app.moment.moment.widget

import android.content.Context

/** Visual layout selected by the home widget renderer. */
enum class WidgetRenderMode {
    PAUSED,
    LOCKED_PLACEHOLDER,
    PRIVATE,
    BLUR,
    FULL,
}

/**
 * Resolved render state for one widget moment.
 *
 * @param skipUnreadBlur When true, show a clear frame (unlock reveal) instead of
 *   the intentional unread blur applied in [resolveWidgetDisplayBitmap].
 */
data class ResolvedWidgetRender(
    val mode: WidgetRenderMode,
    val privacyMode: String,
    val skipUnreadBlur: Boolean,
)

/**
 * Central render decision for the Android home widget.
 *
 * Order:
 * 1. Paused
 * 2. Lock-screen privacy (device locked)
 * 3. Privacy mode (full / blur / private)
 *
 * Unread blur is applied later in [resolveWidgetDisplayBitmap] unless [skipUnreadBlur].
 */
object WidgetRenderResolver {
    fun resolve(
        context: Context,
        data: MomentWidgetData,
        senderId: String?,
        momentId: String,
    ): ResolvedWidgetRender {
        val privacyMode = WidgetPrivacyResolver.resolvePrivacyForSender(context, senderId)

        if (data.paused) {
            return ResolvedWidgetRender(
                mode = WidgetRenderMode.PAUSED,
                privacyMode = privacyMode,
                skipUnreadBlur = false,
            )
        }

        if (data.lockScreenPrivacy && WidgetLockScreen.isDeviceLocked(context)) {
            return ResolvedWidgetRender(
                mode = WidgetRenderMode.LOCKED_PLACEHOLDER,
                privacyMode = privacyMode,
                skipUnreadBlur = false,
            )
        }

        val unlockReveal =
            privacyMode == "full" &&
                WidgetUnlockReveal.consumeClearFrame(context, momentId)

        return when (privacyMode) {
            "private" ->
                ResolvedWidgetRender(
                    mode = WidgetRenderMode.PRIVATE,
                    privacyMode = privacyMode,
                    skipUnreadBlur = unlockReveal,
                )
            "blur" ->
                ResolvedWidgetRender(
                    mode = WidgetRenderMode.BLUR,
                    privacyMode = privacyMode,
                    skipUnreadBlur = unlockReveal,
                )
            else ->
                ResolvedWidgetRender(
                    mode = WidgetRenderMode.FULL,
                    privacyMode = privacyMode,
                    skipUnreadBlur = unlockReveal,
                )
        }
    }
}
