package app.moment.moment.widget

import android.content.Context
import app.moment.moment.useConnection
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import kotlinx.coroutines.runBlocking
import org.json.JSONArray
import org.json.JSONObject

/**
 * Pulls the latest received moments from Supabase while the app process is not running Flutter.
 * Used as backup when FCM is delayed (common on Oppo / OnePlus / Xiaomi).
 */
object WidgetSupabaseSync {
    fun sync(context: Context, promoteLatest: Boolean = false): Boolean {
        val appContext = context.applicationContext
        var credentials = WidgetSyncCredentialsStore.load(appContext) ?: return false

        var rows =
            runCatching {
                fetchRecipientRows(credentials)
            }.getOrElse { error ->
                WidgetMomentSyncLog.error("Background sync fetch failed", error)
                return false
            }

        if (rows == null) {
            val refreshed = refreshAccessToken(appContext, credentials)
            if (!refreshed) return false
            credentials = WidgetSyncCredentialsStore.load(appContext) ?: return false
            rows =
                runCatching { fetchRecipientRows(credentials) }.getOrNull() ?: return false
        }

        val entries = parseEntries(appContext, credentials, rows)
        if (entries.isEmpty()) return false

        val beforeId = WidgetMomentQueue.activeEntry(appContext)?.momentId
        WidgetMomentQueue.mergeQueue(appContext, entries, showLatest = promoteLatest)
        val afterId = WidgetMomentQueue.activeEntry(appContext)?.momentId

        entries.forEach { entry ->
            WidgetMediaDownloader.enqueue(
                appContext,
                entry.momentId,
                entry.imageUrl,
                entry.avatarUrl,
            )
        }

        runBlocking {
            if (promoteLatest || (afterId != null && afterId != beforeId)) {
                MomentWidgetUpdater.updateIncomingMoment(appContext, afterId!!)
            } else {
                MomentWidgetUpdater.updatePreservingView(appContext)
            }
        }
        WidgetMomentSyncLog.fcmReceived("background-sync:${entries.size}")
        return true
    }

    private fun fetchRecipientRows(credentials: WidgetSyncCredentials): JSONArray? {
        val select =
            "moment:moments(id,created_at,caption,storage_path,sender:sender_id(id,display_name,avatar_url))"
        val urlString =
            "${credentials.supabaseUrl}/rest/v1/moment_recipients" +
                "?recipient_id=eq.${credentials.userId}" +
                "&select=${URLEncoder.encode(select, "UTF-8")}" +
                "&order=created_at.desc" +
                "&limit=5"
        val url = URL(urlString)
        val connection = (url.openConnection() as HttpURLConnection).apply {
            connectTimeout = 12_000
            readTimeout = 15_000
            requestMethod = "GET"
            setRequestProperty("apikey", credentials.anonKey)
            setRequestProperty("Authorization", "Bearer ${credentials.accessToken}")
            setRequestProperty("Accept", "application/json")
        }
        return connection.useConnection { conn ->
            when (conn.responseCode) {
                HttpURLConnection.HTTP_OK -> JSONArray(conn.inputStream.bufferedReader().readText())
                HttpURLConnection.HTTP_UNAUTHORIZED -> null
                else -> {
                    WidgetMomentSyncLog.error("Background sync HTTP ${conn.responseCode}")
                    JSONArray()
                }
            }
        }
    }

    private fun refreshAccessToken(
        context: Context,
        credentials: WidgetSyncCredentials,
    ): Boolean {
        val refresh = credentials.refreshToken ?: return false
        val url = URL("${credentials.supabaseUrl}/auth/v1/token?grant_type=refresh_token")
        val body = JSONObject().put("refresh_token", refresh).toString()
        val connection = (url.openConnection() as HttpURLConnection).apply {
            connectTimeout = 12_000
            readTimeout = 15_000
            requestMethod = "POST"
            doOutput = true
            setRequestProperty("apikey", credentials.anonKey)
            setRequestProperty("Content-Type", "application/json")
        }
        connection.outputStream.use { it.write(body.toByteArray()) }
        return connection.useConnection { conn ->
            if (conn.responseCode != HttpURLConnection.HTTP_OK) return false
            val json = JSONObject(conn.inputStream.bufferedReader().readText())
            val access = json.optString("access_token")
            if (access.isBlank()) return false
            WidgetSyncCredentialsStore.updateAccessToken(context, access)
            true
        }
    }

    private fun parseEntries(
        context: Context,
        credentials: WidgetSyncCredentials,
        rows: JSONArray,
    ): List<WidgetMomentEntry> {
        val entries = mutableListOf<WidgetMomentEntry>()
        for (i in 0 until rows.length()) {
            val row = rows.optJSONObject(i) ?: continue
            val moment = row.optJSONObject("moment") ?: continue
            val momentId = moment.optString("id")
            if (momentId.isBlank()) continue

            val sender = moment.optJSONObject("sender")
            val senderId = sender?.optString("id").orEmpty()
            val senderName = sender?.optString("display_name").orEmpty()
            val createdAtMillis =
                WidgetRelativeTime.parseMillis(moment.optString("created_at")) ?: 0L
            val storagePath = moment.optString("storage_path")
            val avatarPath = sender?.optString("avatar_url").orEmpty()

            val imageUrl =
                if (storagePath.isNotBlank()) {
                    signStorageUrl(credentials, "moments", storagePath)
                } else {
                    null
                }
            val avatarUrl =
                if (avatarPath.isNotBlank()) {
                    signStorageUrl(credentials, "avatars", avatarPath)
                } else {
                    null
                }

            entries.add(
                WidgetMomentEntry(
                    momentId = momentId,
                    senderName = senderName,
                    senderId = senderId,
                    imagePath = null,
                    avatarPath = null,
                    caption = moment.optString("caption", ""),
                    createdAtMillis = createdAtMillis,
                    relativeTime =
                        if (createdAtMillis > 0L) {
                            WidgetRelativeTime.format(createdAtMillis)
                        } else {
                            ""
                        },
                    imageUrl = imageUrl,
                    avatarUrl = avatarUrl,
                ),
            )
        }
        return entries
    }

    private fun signStorageUrl(
        credentials: WidgetSyncCredentials,
        bucket: String,
        path: String,
    ): String? {
        val encodedPath = path.split("/").joinToString("/") { URLEncoder.encode(it, "UTF-8") }
        val url = URL("${credentials.supabaseUrl}/storage/v1/object/sign/$bucket/$encodedPath")
        val body = JSONObject().put("expiresIn", 3600).toString()
        val connection = (url.openConnection() as HttpURLConnection).apply {
            connectTimeout = 10_000
            readTimeout = 12_000
            requestMethod = "POST"
            doOutput = true
            setRequestProperty("apikey", credentials.anonKey)
            setRequestProperty("Authorization", "Bearer ${credentials.accessToken}")
            setRequestProperty("Content-Type", "application/json")
        }
        connection.outputStream.use { it.write(body.toByteArray()) }
        return connection.useConnection { conn ->
            if (conn.responseCode != HttpURLConnection.HTTP_OK) return null
            val json = JSONObject(conn.inputStream.bufferedReader().readText())
            val raw =
                json.optString("signedURL").ifBlank { json.optString("signedUrl") }
            if (raw.isBlank()) return null
            if (raw.startsWith("http")) raw else "${credentials.supabaseUrl}/storage/v1$raw"
        }
    }
}
