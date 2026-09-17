package app.moment.moment.widget

/**
 * Parses FCM data payloads into [WidgetMomentEntry] without any network calls.
 */
object WidgetFcmParser {
    fun parseEntry(data: Map<String, String>): WidgetMomentEntry? {
        val type = data.fcm("type").lowercase()
        if (type != "moment" && type != "new_moment") return null

        val momentId =
            data.fcm("momentId").ifBlank { data.fcm("moment_id") }
        if (momentId.isBlank()) return null

        val createdAtMillis =
            WidgetRelativeTime.parseMillis(data.fcm("createdAtMillis"))
                ?: WidgetRelativeTime.parseMillis(data.fcm("created_at"))
                ?: WidgetRelativeTime.parseMillis(data.fcm("createdAt"))
                ?: 0L

        if (createdAtMillis <= 0L) {
            WidgetMomentSyncLog.error("FCM missing createdAt for momentId=$momentId")
        }

        val senderName =
            data.fcm("senderName").ifBlank {
                data.fcm("notificationTitle").ifBlank {
                    data.fcm("headerTitle").ifBlank {
                        data.fcm("title").ifBlank { data.fcm("sender_name") }
                    }
                }
            }

        return WidgetMomentEntry(
            momentId = momentId,
            senderName = senderName,
            senderId = data.fcm("senderId").ifBlank { data.fcm("sender_id") },
            imagePath = null,
            avatarPath = null,
            caption = data.fcm("caption"),
            createdAtMillis = createdAtMillis,
            relativeTime =
                data.fcm("relativeTime").ifBlank {
                    if (createdAtMillis > 0L) {
                        WidgetRelativeTime.format(createdAtMillis)
                    } else {
                        ""
                    }
                },
            imageUrl = data.fcm("imageUrl").ifBlank { data.fcm("image_url") }.ifBlank { null },
            avatarUrl = data.fcm("avatarUrl").ifBlank { data.fcm("avatar_url") }.ifBlank { null },
            isUnread = true,
        )
    }

    private fun Map<String, String>.fcm(key: String): String {
        if (containsKey(key)) return get(key).orEmpty()
        val lower = key.lowercase()
        if (containsKey(lower)) return get(lower).orEmpty()
        return entries.firstOrNull { it.key.equals(key, ignoreCase = true) }?.value.orEmpty()
    }
}
