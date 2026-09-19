package app.moment.moment.widget

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.background
import androidx.glance.appwidget.cornerRadius
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider

@Composable
fun WidgetMomentOverlays(parsed: ParsedMomentCaption) {
    if (!parsed.hasOverlays) return

    Box(modifier = GlanceModifier.fillMaxSize()) {
        Column(
            modifier =
                GlanceModifier
                    .fillMaxSize()
                    .padding(6.dp),
            horizontalAlignment = Alignment.Start,
            verticalAlignment = Alignment.Top,
        ) {
            parsed.reviewLine?.let {
                WidgetOverlayPill(text = it, accent = true)
                Spacer(GlanceModifier.height(4.dp))
            }
            parsed.location?.let {
                WidgetOverlayPill(text = "📍 $it")
                Spacer(GlanceModifier.height(4.dp))
            }
            parsed.time?.let {
                WidgetOverlayPill(text = "🕐 $it")
            }
        }

        Column(
            modifier =
                GlanceModifier
                    .fillMaxSize()
                    .padding(6.dp),
            horizontalAlignment = Alignment.End,
            verticalAlignment = Alignment.Top,
        ) {
            parsed.weather?.let {
                WidgetOverlayPill(text = "🌤 $it")
                Spacer(GlanceModifier.height(4.dp))
            }
            parsed.streak?.let {
                WidgetOverlayPill(text = "🔥 $it", accent = true)
            }
        }

        if (parsed.stickers.isNotEmpty()) {
            Column(
                modifier =
                    GlanceModifier
                        .fillMaxSize()
                        .padding(6.dp),
                horizontalAlignment = Alignment.End,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                for (sticker in parsed.stickers.take(3)) {
                    WidgetOverlayPill(text = sticker, sticker = true)
                    Spacer(GlanceModifier.height(4.dp))
                }
            }
        }
    }
}

@Composable
private fun WidgetOverlayPill(
    text: String,
    accent: Boolean = false,
    sticker: Boolean = false,
) {
    val bg =
        when {
            accent -> Color(0xE6FFD54F)
            sticker -> Color(0xCC1C1C1E)
            else -> Color(0x99000000)
        }
    val fg =
        when {
            accent -> Color(0xFF3D2800)
            else -> Color.White
        }

    Box(
        modifier =
            GlanceModifier
                .background(ColorProvider(bg))
                .cornerRadius(999.dp)
                .padding(horizontal = 8.dp, vertical = 4.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = text,
            maxLines = 1,
            style =
                TextStyle(
                    color = ColorProvider(fg),
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Bold,
                ),
        )
    }
}
