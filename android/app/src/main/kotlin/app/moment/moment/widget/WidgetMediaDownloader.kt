package app.moment.moment.widget

import android.content.Context
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

/**
 * Downloads widget media after the metadata widget update.
 * Only redraws when the downloaded moment is still the visible card.
 */
object WidgetMediaDownloader {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    fun enqueue(
        context: Context,
        momentId: String,
        imageUrl: String?,
        avatarUrl: String?,
    ) {
        if (momentId.isBlank()) return
        if (imageUrl.isNullOrBlank() && avatarUrl.isNullOrBlank()) return

        val appContext = context.applicationContext
        scope.launch {
            WidgetMomentSyncLog.mediaDownloadStart(momentId)
            val current = WidgetMomentQueue.findEntry(appContext, momentId) ?: return@launch
            val privacyMode =
                WidgetPrivacyResolver.resolvePrivacyForSender(appContext, current.senderId)
            if (!shouldCacheMomentImage(privacyMode)) {
                WidgetPrivateImageGuard.purgeMomentImage(appContext, current)
                return@launch
            }

            val imagePath =
                if (!imageUrl.isNullOrBlank()) {
                    WidgetNetworkImage.download(appContext, imageUrl, "moment_$momentId.jpg")
                } else {
                    current.imagePath
                }

            val avatarPath =
                if (!avatarUrl.isNullOrBlank()) {
                    WidgetNetworkImage.download(appContext, avatarUrl, "avatar_$momentId.jpg")
                } else {
                    current.avatarPath
                }

            if (imagePath.isNullOrBlank() && avatarPath.isNullOrBlank()) return@launch

            WidgetMomentQueue.patchMedia(
                appContext,
                momentId = momentId,
                imagePath = imagePath,
                avatarPath = avatarPath,
            )

            val visible = WidgetMomentQueue.activeEntry(appContext)?.momentId
            if (visible != momentId) {
                WidgetMomentSyncLog.error("Media skip refresh: $momentId visible=$visible")
                return@launch
            }

            WidgetMomentSyncLog.mediaDownloadDone(
                momentId,
                hasImage = !imagePath.isNullOrBlank(),
                hasAvatar = !avatarPath.isNullOrBlank(),
            )
            runBlocking { MomentWidgetUpdater.updatePreservingView(appContext) }
            WidgetRenderLatency.onPhotoRendered(momentId)
        }
    }

    private fun shouldCacheMomentImage(privacyMode: String): Boolean =
        WidgetPrivateImageGuard.shouldCacheMomentImage(privacyMode)
}
