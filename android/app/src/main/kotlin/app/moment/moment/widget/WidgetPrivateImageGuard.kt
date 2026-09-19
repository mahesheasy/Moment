package app.moment.moment.widget

import android.content.Context
import java.io.File

/**
 * Private privacy mode must not retain widget moment photos for display.
 *
 * Guarantees:
 * - The Glance layout never receives a decoded bitmap in private mode.
 * - Cached moment image files are removed when private mode is active.
 *
 * Does not delete remote URLs or in-app gallery data — only widget-local files.
 */
object WidgetPrivateImageGuard {
    fun shouldCacheMomentImage(privacyMode: String): Boolean = privacyMode != "private"

    fun purgeMomentImage(
        context: Context,
        entry: WidgetMomentEntry,
    ) {
        purgePath(entry.imagePath)
        if (!entry.imagePath.isNullOrBlank()) {
            WidgetMomentQueue.patchEntries(
                context,
                listOf(entry.copy(imagePath = null)),
            )
        }
    }

    fun purgePath(path: String?) {
        if (path.isNullOrBlank()) return
        try {
            File(path).delete()
        } catch (_: Exception) {
        }
    }
}
