package app.moment.moment.widget

import android.content.Context
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

object WidgetNetworkImage {
    fun download(
        context: Context,
        url: String?,
        fileName: String,
    ): String? {
        if (url.isNullOrBlank()) return null

        return try {
            val connection =
                (URL(url).openConnection() as HttpURLConnection).apply {
                    connectTimeout = 15_000
                    readTimeout = 20_000
                    requestMethod = "GET"
                    instanceFollowRedirects = true
                    setRequestProperty("User-Agent", "Moment/1.0 (Android)")
                    setRequestProperty("Accept", "image/*,*/*")
                }
            connection.connect()
            if (connection.responseCode != HttpURLConnection.HTTP_OK) {
                return null
            }
            val bytes = connection.inputStream.use { it.readBytes() }
            connection.disconnect()
            if (bytes.isEmpty()) return null

            val dir = File(context.filesDir, "widget")
            if (!dir.exists()) dir.mkdirs()
            WidgetBitmap.writeDownsampled(bytes, File(dir, fileName))
        } catch (_: Exception) {
            null
        }
    }
}
