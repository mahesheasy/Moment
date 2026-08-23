package app.moment.moment.widget

internal object WidgetRelativeTime {
    fun format(createdAtMillis: Long, nowMillis: Long = System.currentTimeMillis()): String {
        if (createdAtMillis <= 0L) return ""
        val diff = nowMillis - createdAtMillis
        val seconds = diff / 1000
        val minutes = seconds / 60
        val hours = minutes / 60
        val days = hours / 24
        return when {
            diff < 0 || seconds < 45 -> "now"
            minutes < 60 -> "${minutes}m ago"
            hours < 24 -> "${hours}h ago"
            days < 7 -> "${days}d ago"
            days < 30 -> "${days / 7}w ago"
            else -> "${days / 30}mo ago"
        }
    }

    fun parseMillis(raw: String?): Long? {
        if (raw.isNullOrBlank()) return null
        raw.toLongOrNull()?.let { return it }
        return try {
            java.time.Instant.parse(raw).toEpochMilli()
        } catch (_: Exception) {
            try {
                java.time.OffsetDateTime.parse(raw).toInstant().toEpochMilli()
            } catch (_: Exception) {
                null
            }
        }
    }
}
