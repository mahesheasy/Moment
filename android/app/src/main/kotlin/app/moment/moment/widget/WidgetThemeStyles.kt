package app.moment.moment.widget

import androidx.compose.ui.graphics.Color
import androidx.glance.text.FontFamily
import androidx.glance.text.FontWeight
import androidx.glance.unit.ColorProvider

data class WidgetThemeStyle(
    val background: ColorProvider,
    val headerBackground: ColorProvider,
    val labelColor: ColorProvider,
    val secondaryColor: ColorProvider,
    val accentColor: ColorProvider,
    val actionBackground: ColorProvider,
    val contentPaddingDp: Int,
    val photoCornerDp: Int,
    val fontWeight: FontWeight,
    val fontFamily: FontFamily?,
    val useMemoryOverlay: Boolean,
)

object WidgetThemeStyles {
    private val violet = Color(0xFFFF6B8A)
    private val darkBg = Color(0xFF0B090E)
    private val darkHeader = Color(0xFF16121A)
    private val darkSecondary = Color(0xFFC4B3BB)

    fun parseAccent(hex: String): Color {
        val normalized = hex.removePrefix("#")
        val value =
            try {
                ("FF$normalized").toLong(16)
            } catch (_: Exception) {
                0xFFFF6B8A
            }
        return Color(value)
    }

    fun resolve(theme: String, accentHex: String, typography: String): WidgetThemeStyle {
        val accent = parseAccent(accentHex)
        val accentProvider = ColorProvider(accent)
        val (fontWeight, fontFamily) = typographyStyle(typography)

        return when (theme) {
            "glass" ->
                WidgetThemeStyle(
                    background = ColorProvider(Color(0xFF121218)),
                    headerBackground = ColorProvider(Color(0x661A1A1F)),
                    labelColor = ColorProvider(Color(0xFFFFFFFF)),
                    secondaryColor = ColorProvider(Color(0xB3FFFFFF)),
                    accentColor = accentProvider,
                    actionBackground = ColorProvider(Color(0x99000000)),
                    contentPaddingDp = 10,
                    photoCornerDp = 16,
                    fontWeight = fontWeight,
                    fontFamily = fontFamily,
                    useMemoryOverlay = false,
                )
            "film" ->
                WidgetThemeStyle(
                    background = ColorProvider(Color(0xFF0D0D0D)),
                    headerBackground = ColorProvider(Color(0xFF141414)),
                    labelColor = accentProvider,
                    secondaryColor = ColorProvider(Color(0xFF888888)),
                    accentColor = accentProvider,
                    actionBackground = ColorProvider(Color(0xCC000000)),
                    contentPaddingDp = 12,
                    photoCornerDp = 4,
                    fontWeight = fontWeight,
                    fontFamily = fontFamily,
                    useMemoryOverlay = false,
                )
            "polaroid" ->
                WidgetThemeStyle(
                    background = ColorProvider(Color(0xFFF7F4EF)),
                    headerBackground = ColorProvider(Color(0xFFF0EBE3)),
                    labelColor = ColorProvider(Color(0xFF2D2A26)),
                    secondaryColor = accentProvider,
                    accentColor = accentProvider,
                    actionBackground = ColorProvider(Color(0x66000000)),
                    contentPaddingDp = 10,
                    photoCornerDp = 2,
                    fontWeight = fontWeight,
                    fontFamily = fontFamily,
                    useMemoryOverlay = false,
                )
            "midnight" ->
                WidgetThemeStyle(
                    background = ColorProvider(Color(0xFF0B132B)),
                    headerBackground = ColorProvider(Color(0xFF111D3A)),
                    labelColor = ColorProvider(Color(0xFFE0E7FF)),
                    secondaryColor = accentProvider,
                    accentColor = accentProvider,
                    actionBackground = ColorProvider(Color(0x990B132B)),
                    contentPaddingDp = 10,
                    photoCornerDp = 16,
                    fontWeight = fontWeight,
                    fontFamily = fontFamily,
                    useMemoryOverlay = false,
                )
            "sunset" ->
                WidgetThemeStyle(
                    background = ColorProvider(Color(0xFF3D1F1F)),
                    headerBackground = ColorProvider(Color(0xFF4A2626)),
                    labelColor = ColorProvider(Color(0xFFFFE8D6)),
                    secondaryColor = accentProvider,
                    accentColor = accentProvider,
                    actionBackground = ColorProvider(Color(0x993D1F1F)),
                    contentPaddingDp = 10,
                    photoCornerDp = 16,
                    fontWeight = fontWeight,
                    fontFamily = fontFamily,
                    useMemoryOverlay = false,
                )
            "love" ->
                WidgetThemeStyle(
                    background = ColorProvider(Color(0xFF3A1F2B)),
                    headerBackground = ColorProvider(Color(0xFF452535)),
                    labelColor = ColorProvider(Color(0xFFFFE4EC)),
                    secondaryColor = accentProvider,
                    accentColor = accentProvider,
                    actionBackground = ColorProvider(Color(0x993A1F2B)),
                    contentPaddingDp = 10,
                    photoCornerDp = 16,
                    fontWeight = fontWeight,
                    fontFamily = fontFamily,
                    useMemoryOverlay = false,
                )
            "family" ->
                WidgetThemeStyle(
                    background = ColorProvider(Color(0xFF1A2438)),
                    headerBackground = ColorProvider(Color(0xFF243048)),
                    labelColor = ColorProvider(Color(0xFFE8F2FF)),
                    secondaryColor = accentProvider,
                    accentColor = accentProvider,
                    actionBackground = ColorProvider(Color(0x991A2438)),
                    contentPaddingDp = 10,
                    photoCornerDp = 16,
                    fontWeight = fontWeight,
                    fontFamily = fontFamily,
                    useMemoryOverlay = false,
                )
            "friends" ->
                WidgetThemeStyle(
                    background = ColorProvider(Color(0xFF142820)),
                    headerBackground = ColorProvider(Color(0xFF1C342C)),
                    labelColor = ColorProvider(Color(0xFFE8FFF4)),
                    secondaryColor = accentProvider,
                    accentColor = accentProvider,
                    actionBackground = ColorProvider(Color(0x99142820)),
                    contentPaddingDp = 10,
                    photoCornerDp = 16,
                    fontWeight = fontWeight,
                    fontFamily = fontFamily,
                    useMemoryOverlay = false,
                )
            "bestie" ->
                WidgetThemeStyle(
                    background = ColorProvider(Color(0xFF2A2014)),
                    headerBackground = ColorProvider(Color(0xFF352818)),
                    labelColor = ColorProvider(Color(0xFFFFF0DC)),
                    secondaryColor = accentProvider,
                    accentColor = accentProvider,
                    actionBackground = ColorProvider(Color(0x992A2014)),
                    contentPaddingDp = 10,
                    photoCornerDp = 16,
                    fontWeight = fontWeight,
                    fontFamily = fontFamily,
                    useMemoryOverlay = false,
                )
            "retro" ->
                WidgetThemeStyle(
                    background = ColorProvider(Color(0xFF2A2118)),
                    headerBackground = ColorProvider(Color(0xFF332820)),
                    labelColor = ColorProvider(Color(0xFFF5DEB3)),
                    secondaryColor = accentProvider,
                    accentColor = accentProvider,
                    actionBackground = ColorProvider(Color(0x992A2118)),
                    contentPaddingDp = 10,
                    photoCornerDp = 8,
                    fontWeight = fontWeight,
                    fontFamily = fontFamily,
                    useMemoryOverlay = false,
                )
            "memory" ->
                WidgetThemeStyle(
                    background = ColorProvider(darkBg),
                    headerBackground = ColorProvider(Color(0x00000000)),
                    labelColor = ColorProvider(Color(0xFFFFFFFF)),
                    secondaryColor = ColorProvider(Color(0xE6FFFFFF)),
                    accentColor = accentProvider,
                    actionBackground = ColorProvider(Color(0x99000000)),
                    contentPaddingDp = 0,
                    photoCornerDp = 20,
                    fontWeight = fontWeight,
                    fontFamily = fontFamily,
                    useMemoryOverlay = true,
                )
            else ->
                WidgetThemeStyle(
                    background = ColorProvider(darkBg),
                    headerBackground = ColorProvider(darkHeader),
                    labelColor = ColorProvider(Color(0xFFF8F1F4)),
                    secondaryColor = ColorProvider(darkSecondary),
                    accentColor = ColorProvider(violet),
                    actionBackground = ColorProvider(Color(0xCC16121A)),
                    contentPaddingDp = 10,
                    photoCornerDp = 16,
                    fontWeight = fontWeight,
                    fontFamily = fontFamily,
                    useMemoryOverlay = false,
                )
        }
    }

    private fun typographyStyle(typography: String): Pair<FontWeight, FontFamily?> {
        return when (typography) {
            "serif" -> FontWeight.Medium to FontFamily.Serif
            "rounded" -> FontWeight.Bold to FontFamily.SansSerif
            "mono" -> FontWeight.Normal to FontFamily.Monospace
            else -> FontWeight.Medium to null
        }
    }

    fun themeEmoji(theme: String): String =
        when (theme) {
            "love" -> "💕"
            "family" -> "👨‍👩‍👧"
            "friends" -> "👥"
            "bestie" -> "✨"
            "glass" -> "🪟"
            "film" -> "🎞️"
            "polaroid" -> "📷"
            "midnight" -> "🌙"
            "sunset" -> "🌅"
            "retro" -> "📼"
            "memory" -> "🕰️"
            else -> "◻️"
        }

    fun themeLabel(theme: String): String =
        when (theme) {
            "love" -> "Love"
            "family" -> "Family"
            "friends" -> "Friends"
            "bestie" -> "Bestie"
            "glass" -> "Glass"
            "film" -> "Film"
            "polaroid" -> "Polaroid"
            "midnight" -> "Midnight"
            "sunset" -> "Sunset"
            "retro" -> "Retro"
            "memory" -> "Memory"
            else -> "Moment"
        }

    fun photoScrim(theme: String, accent: Color): Color =
        when (theme) {
            "love" -> Color(0xCC4A2030)
            "family" -> Color(0xCC1A2438)
            "friends" -> Color(0xCC142820)
            "bestie" -> Color(0xCC2A2014)
            "glass" -> Color(0xAA121218)
            "film" -> Color(0xCC0D0D0D)
            "polaroid" -> Color(0xCC2D2A26)
            "midnight" -> Color(0xCC0B132B)
            "sunset" -> Color(0xCC3D1F1F)
            "retro" -> Color(0xCC2A2118)
            "memory" -> Color(0xCC0B090E)
            else -> Color(0xCC000000)
        }.let { base ->
            Color(
                red = (base.red * 0.65f + accent.red * 0.35f).coerceIn(0f, 1f),
                green = (base.green * 0.65f + accent.green * 0.35f).coerceIn(0f, 1f),
                blue = (base.blue * 0.65f + accent.blue * 0.35f).coerceIn(0f, 1f),
                alpha = base.alpha,
            )
        }
}
