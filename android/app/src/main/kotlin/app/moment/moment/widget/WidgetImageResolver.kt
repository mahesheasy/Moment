package app.moment.moment.widget

import android.content.Context
import java.io.File

object WidgetImageResolver {
    fun ensureCached(
        context: Context,
        entry: WidgetMomentEntry,
    ): WidgetMomentEntry {
        val imagePath =
            resolvePath(
                context = context,
                currentPath = entry.imagePath,
                url = entry.imageUrl,
                fileName = "moment_${entry.momentId}.jpg",
            )
        val avatarPath =
            resolvePath(
                context = context,
                currentPath = entry.avatarPath,
                url = entry.avatarUrl,
                fileName = "avatar_${entry.momentId}.jpg",
            )
        if (imagePath == entry.imagePath && avatarPath == entry.avatarPath) {
            return entry
        }
        return entry.copy(imagePath = imagePath, avatarPath = avatarPath)
    }

    private fun resolvePath(
        context: Context,
        currentPath: String?,
        url: String?,
        fileName: String,
    ): String? {
        if (!currentPath.isNullOrBlank() && File(currentPath).exists()) {
            return currentPath
        }
        return WidgetNetworkImage.download(context, url, fileName) ?: currentPath
    }
}
