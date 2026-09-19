package app.moment.moment.widget

/**
 * Parses a moment [caption] produced by Flutter's composedCaption:
 * user text, review stars, location/weather/time emojis, streak, #stickers.
 */
data class ParsedMomentCaption(
    val userCaption: String = "",
    val location: String? = null,
    val weather: String? = null,
    val time: String? = null,
    val streak: String? = null,
    val stickers: List<String> = emptyList(),
    val reviewLine: String? = null,
) {
    val hasOverlays: Boolean
        get() =
            location != null ||
                weather != null ||
                time != null ||
                streak != null ||
                stickers.isNotEmpty() ||
                reviewLine != null
}

object WidgetCaptionParser {
    fun parse(caption: String): ParsedMomentCaption {
        if (caption.isBlank()) return ParsedMomentCaption()

        val userLines = mutableListOf<String>()
        var location: String? = null
        var weather: String? = null
        var time: String? = null
        var streak: String? = null
        val stickers = mutableListOf<String>()
        var reviewLine: String? = null

        for (line in caption.lines().map { it.trim() }.filter { it.isNotEmpty() }) {
            when {
                line.startsWith("📍") ->
                    location = line.removePrefix("📍").trim()
                line.startsWith("🌤") ->
                    weather = line.removePrefix("🌤").trim()
                line.startsWith("🕐") ->
                    time = line.removePrefix("🕐").trim()
                line.startsWith("🔥") ->
                    streak = line.removePrefix("🔥").trim()
                line.startsWith("#") ->
                    stickers.add(formatSticker(line.removePrefix("#").trim()))
                line.contains('★') || line.contains('☆') ->
                    reviewLine = line
                else -> userLines.add(line)
            }
        }

        return ParsedMomentCaption(
            userCaption = userLines.joinToString("\n"),
            location = location,
            weather = weather,
            time = time,
            streak = streak,
            stickers = stickers,
            reviewLine = reviewLine,
        )
    }

    /** Streak count only when the sender included 🔥 in the moment caption. */
    fun streakCountFromCaption(caption: String): Int? {
        val streak = parse(caption).streak ?: return null
        val digits = streak.filter { it.isDigit() }
        if (digits.isEmpty()) return null
        return digits.toIntOrNull()?.takeIf { it > 0 }
    }

    private fun formatSticker(tag: String): String {
        val emoji =
            when {
                tag.contains("party", ignoreCase = true) -> "🪩"
                tag.contains("ootd", ignoreCase = true) -> "🕶️"
                tag.contains("miss", ignoreCase = true) -> "🥰"
                else -> "✨"
            }
        val label =
            when {
                tag.contains("party", ignoreCase = true) -> "Party Time!"
                tag.contains("ootd", ignoreCase = true) -> "OOTD"
                tag.contains("miss", ignoreCase = true) -> "Miss you"
                else -> tag
            }
        return "$emoji $label"
    }
}
