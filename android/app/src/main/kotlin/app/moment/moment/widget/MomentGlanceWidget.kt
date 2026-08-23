package app.moment.moment.widget

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.clickable
import androidx.glance.action.actionParametersOf
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class MomentGlanceWidget : GlanceAppWidget() {
    override val sizeMode: SizeMode = SizeMode.Single

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val data =
            try {
                MomentWidgetDataStore.load(context)
            } catch (error: Exception) {
                Log.e(TAG, "Failed to load widget data", error)
                emptyWidgetData()
            }

        val bitmap =
            withContext(Dispatchers.IO) {
                try {
                    val decoded =
                        if (data.hasMoment) WidgetBitmap.decode(data.imagePath) else null
                    if (decoded != null && data.privacyMode == "blur") {
                        WidgetBitmap.blur(decoded)
                    } else {
                        decoded
                    }
                } catch (error: Exception) {
                    Log.e(TAG, "Failed to decode widget image", error)
                    null
                }
            }

        val avatarBitmap =
            withContext(Dispatchers.IO) {
                try {
                    if (data.avatarPath != null) {
                        WidgetBitmap.decode(data.avatarPath)
                    } else {
                        null
                    }
                } catch (error: Exception) {
                    Log.e(TAG, "Failed to decode widget avatar", error)
                    null
                }
            }

        provideContent {
            MomentWidgetContent(data = data, bitmap = bitmap, avatarBitmap = avatarBitmap)
        }
    }

    companion object {
        private const val TAG = "MomentGlanceWidget"
    }
}

private fun emptyWidgetData(): MomentWidgetData =
    MomentWidgetData(
        hasMoment = false,
        senderName = "",
        senderId = "",
        momentId = "",
        imagePath = null,
        caption = "",
        relativeTime = "",
        createdAtMillis = 0L,
        widgetMode = "latest",
        headerEmoji = "",
        avatarPath = null,
        theme = "minimal",
        accentColor = "#FF6B8A",
        typography = "default",
        displaySize = "large",
        privacyMode = "full",
        showSender = true,
        showTimestamp = true,
        showCaptions = false,
        lockScreenPrivacy = true,
        paused = false,
        recentIndex = 0,
        recentCount = 0,
    )

private fun launchMainActivityIntent(): Intent =
    Intent(Intent.ACTION_MAIN).apply {
        setClassName("app.moment.moment", "app.moment.moment.MainActivity")
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
    }

private fun launchDeepLink(path: String): Intent =
    Intent(Intent.ACTION_VIEW, Uri.parse("moment://$path")).apply {
        setClassName("app.moment.moment", "app.moment.moment.MainActivity")
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
    }

@Composable
private fun MomentWidgetContent(
    data: MomentWidgetData,
    bitmap: Bitmap?,
    avatarBitmap: Bitmap?,
) {
    val style = WidgetThemeStyles.resolve(data.theme, data.accentColor, data.typography)
    val liveTime =
        WidgetRelativeTime.format(data.createdAtMillis).ifBlank { data.relativeTime }

    Box(
        modifier =
            GlanceModifier
                .fillMaxSize()
                .background(ColorProvider(Color.Black))
                .cornerRadius(24.dp)
                .padding(10.dp),
    ) {
        Box(
            modifier =
                GlanceModifier
                    .fillMaxSize()
                    .background(style.background)
                    .cornerRadius(16.dp)
                    .padding(2.dp)
                    .background(style.accentColor)
                    .cornerRadius(14.dp)
                    .padding(2.dp)
                    .background(style.background)
                    .cornerRadius(12.dp),
        ) {
            when {
                data.paused ->
                    PrivateMomentLayout(
                        title = "Widget paused",
                        from = data.senderName.ifBlank { "Moment" },
                        action = "Tap to resume",
                        style = style,
                        open = actionStartActivity(launchMainActivityIntent()),
                    )
                data.theme == "memory" && bitmap != null ->
                    MemoryMomentLayout(
                        data = data,
                        bitmap = bitmap,
                        style = style,
                    )
                data.privacyMode == "private" && data.hasMoment ->
                    PrivateMomentLayout(
                        title = "New Moment",
                        from = "From ${data.senderName.ifBlank { "a friend" }}",
                        action = "Tap to reveal",
                        style = style,
                        open = openMomentAction(data),
                    )
                bitmap != null && data.privacyMode == "blur" ->
                    BlurMomentLayout(
                        data = data,
                        bitmap = bitmap,
                        style = style,
                        liveTime = liveTime,
                    )
                bitmap != null ->
                    FullMomentLayout(
                        data = data,
                        bitmap = bitmap,
                        avatarBitmap = avatarBitmap,
                        style = style,
                        liveTime = liveTime,
                    )
                data.hasMoment ->
                    PendingMomentLayout(
                        data = data,
                        style = style,
                        liveTime = liveTime,
                    )
                else -> EmptyWidgetLayout(data = data, style = style)
            }
        }
    }
}

@Composable
private fun FullMomentLayout(
    data: MomentWidgetData,
    bitmap: Bitmap,
    avatarBitmap: Bitmap?,
    style: WidgetThemeStyle,
    liveTime: String,
) {
    val open = openMomentAction(data)
    val name = if (data.showSender) data.senderName.ifBlank { "Moment" } else ""
    val scale = layoutScale(data.displaySize)
    val accent = WidgetThemeStyles.parseAccent(data.accentColor)
    val scrim = WidgetThemeStyles.photoScrim(data.theme, accent)
    val headerEmoji =
        data.headerEmoji.ifBlank { WidgetThemeStyles.themeEmoji(data.theme) }
    val themeLabel = WidgetThemeStyles.themeLabel(data.theme)

    Box(
        modifier =
            GlanceModifier
                .fillMaxSize()
                .clickable(open),
        contentAlignment = Alignment.TopStart,
    ) {
        Image(
            provider = ImageProvider(bitmap),
            contentDescription = "Moment from ${data.senderName}",
            modifier = GlanceModifier.fillMaxSize(),
            contentScale = ContentScale.Crop,
        )
        Box(
            modifier =
                GlanceModifier
                    .fillMaxSize()
                    .background(ColorProvider(accent.copy(alpha = 0.12f))),
        ) {}
        Row(
            modifier =
                GlanceModifier
                    .fillMaxWidth()
                    .padding(scale.pad.dp)
                    .background(ColorProvider(Color(0x99000000)))
                    .cornerRadius(10.dp)
                    .padding(horizontal = 8.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = "$headerEmoji  $themeLabel",
                maxLines = 1,
                style =
                    textStyle(
                        style,
                        style.accentColor,
                        scale.headerSize,
                        FontWeight.Bold,
                    ),
            )
        }
        if (avatarBitmap != null) {
            Box(
                modifier =
                    GlanceModifier
                        .padding(scale.pad.dp)
                        .padding(top = 34.dp)
                        .width(32.dp)
                        .height(32.dp)
                        .background(style.accentColor)
                        .cornerRadius(16.dp),
                contentAlignment = Alignment.Center,
            ) {
                Image(
                    provider = ImageProvider(avatarBitmap),
                    contentDescription = "Sender avatar",
                    modifier =
                        GlanceModifier
                            .width(28.dp)
                            .height(28.dp)
                            .cornerRadius(14.dp),
                    contentScale = ContentScale.Crop,
                )
            }
        }
        Box(
            modifier = GlanceModifier.fillMaxSize(),
            contentAlignment = Alignment.BottomStart,
        ) {
            Box(
                modifier =
                    GlanceModifier
                        .fillMaxWidth()
                        .height(scale.overlayHeight.dp)
                        .background(ColorProvider(scrim)),
            ) {}
            Row(
                modifier =
                    GlanceModifier
                        .fillMaxWidth()
                        .padding(
                            start = scale.pad.dp,
                            end = scale.pad.dp,
                            bottom = scale.pad.dp,
                            top = (scale.overlayHeight / 3).dp,
                        ),
                verticalAlignment = Alignment.Bottom,
            ) {
                Column(modifier = GlanceModifier.defaultWeight()) {
                    if (name.isNotBlank()) {
                        Text(
                            text = name,
                            maxLines = 1,
                            style =
                                textStyle(
                                    style,
                                    ColorProvider(Color.White),
                                    scale.nameSize,
                                    FontWeight.Bold,
                                ),
                        )
                    }
                    if (data.showTimestamp && liveTime.isNotBlank()) {
                        Text(
                            text = liveTime,
                            modifier = GlanceModifier.padding(top = 2.dp),
                            style =
                                textStyle(
                                    style,
                                    ColorProvider(Color(0xD1FFFFFF)),
                                    scale.timeSize,
                                ),
                        )
                    }
                    if (data.showCaptions && data.caption.isNotBlank()) {
                        Text(
                            text = data.caption,
                            maxLines = 1,
                            modifier = GlanceModifier.padding(top = 2.dp),
                            style =
                                textStyle(
                                    style,
                                    style.accentColor,
                                    scale.timeSize,
                                ),
                        )
                    }
                }
                Box(
                    modifier =
                        GlanceModifier
                            .width(30.dp)
                            .height(30.dp)
                            .background(ColorProvider(Color(0x66000000)))
                            .cornerRadius(8.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = "♡",
                        style =
                            textStyle(
                                style,
                                style.accentColor,
                                scale.nameSize + 6,
                                FontWeight.Bold,
                            ),
                    )
                }
            }
        }
        if (data.recentCount > 1) {
            Box(
                modifier =
                    GlanceModifier
                        .fillMaxWidth()
                        .padding(bottom = (scale.overlayHeight + 8).dp),
                contentAlignment = Alignment.Center,
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    repeat(data.recentCount.coerceAtMost(5)) { index ->
                        Text(
                            text = if (index == data.recentIndex) "●" else "○",
                            modifier = GlanceModifier.padding(horizontal = 2.dp),
                            style =
                                textStyle(
                                    style,
                                    if (index == data.recentIndex) {
                                        style.accentColor
                                    } else {
                                        ColorProvider(Color(0x99FFFFFF))
                                    },
                                    9,
                                ),
                        )
                    }
                }
            }
            Row(
                modifier = GlanceModifier.fillMaxSize(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(
                    modifier =
                        GlanceModifier
                            .width(44.dp)
                            .fillMaxHeight()
                            .clickable(
                                actionRunCallback<WidgetCycleAction>(
                                    actionParametersOf(WidgetCycleAction.DeltaKey to -1),
                                ),
                            ),
                ) {}
                Spacer(modifier = GlanceModifier.defaultWeight())
                Box(
                    modifier =
                        GlanceModifier
                            .width(44.dp)
                            .fillMaxHeight()
                            .clickable(
                                actionRunCallback<WidgetCycleAction>(
                                    actionParametersOf(WidgetCycleAction.DeltaKey to 1),
                                ),
                            ),
                ) {}
            }
        }
    }
}

private data class WidgetLayoutScale(
    val overlayHeight: Int,
    val nameSize: Int,
    val timeSize: Int,
    val headerSize: Int,
    val pad: Int,
)

private fun layoutScale(displaySize: String): WidgetLayoutScale =
    when (displaySize) {
        "small" -> WidgetLayoutScale(48, 11, 9, 9, 6)
        "medium" -> WidgetLayoutScale(58, 12, 10, 10, 8)
        else -> WidgetLayoutScale(72, 14, 11, 11, 10)
    }

@Composable
private fun BlurMomentLayout(
    data: MomentWidgetData,
    bitmap: Bitmap,
    style: WidgetThemeStyle,
    liveTime: String,
) {
    val open = openMomentAction(data)
    val name = data.senderName.ifBlank { "Moment" }

    Box(
        modifier =
            GlanceModifier
                .fillMaxSize()
                .padding(8.dp)
                .clickable(open),
        contentAlignment = Alignment.BottomStart,
    ) {
        Image(
            provider = ImageProvider(bitmap),
            contentDescription = "Hidden moment from ${data.senderName}",
            modifier =
                GlanceModifier
                    .fillMaxSize()
                    .cornerRadius(16.dp),
            contentScale = ContentScale.Crop,
        )
        Box(
            modifier =
                GlanceModifier
                    .fillMaxSize()
                    .cornerRadius(16.dp)
                    .background(ColorProvider(Color(0x59000000))),
        ) {}
        Column(
            modifier =
                GlanceModifier
                    .fillMaxSize()
                    .padding(12.dp),
            verticalAlignment = Alignment.Top,
        ) {
            if (data.showSender) {
                Text(
                    text = "❤️  $name",
                    maxLines = 1,
                    style = textStyle(style, ColorProvider(Color.White), 12, FontWeight.Bold),
                )
            }
            Spacer(GlanceModifier.defaultWeight())
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.Bottom,
            ) {
                Column(modifier = GlanceModifier.defaultWeight()) {
                    if (data.showSender) {
                        Text(
                            text = name,
                            maxLines = 1,
                            style = textStyle(style, ColorProvider(Color.White), 14, FontWeight.Bold),
                        )
                    }
                    if (data.showTimestamp && liveTime.isNotBlank()) {
                        Text(
                            text = "🐣  $liveTime",
                            modifier = GlanceModifier.padding(top = 2.dp),
                            style = textStyle(style, ColorProvider(Color(0xCCFFFFFF)), 12),
                        )
                    }
                }
                Text(
                    text = "♡",
                    style = textStyle(style, ColorProvider(Color.White), 14, FontWeight.Bold),
                )
            }
        }
    }
}

@Composable
private fun PrivateMomentLayout(
    title: String,
    from: String,
    action: String,
    style: WidgetThemeStyle,
    open: androidx.glance.action.Action,
) {
    Column(
        modifier =
            GlanceModifier
                .fillMaxSize()
                .clickable(open)
                .padding(18.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = "🌸  $title",
            style = textStyle(style, ColorProvider(Color.White), 12),
        )
        Spacer(GlanceModifier.height(8.dp))
        Text(
            text = from,
            maxLines = 1,
            style = textStyle(style, ColorProvider(Color.White), 14, FontWeight.Bold),
        )
        Spacer(GlanceModifier.height(8.dp))
        Text(
            text = action,
            style = textStyle(style, ColorProvider(Color(0x8CFFFFFF)), 10),
        )
    }
}

@Composable
private fun MemoryMomentLayout(
    data: MomentWidgetData,
    bitmap: Bitmap,
    style: WidgetThemeStyle,
) {
    val open = openMomentAction(data)
    Column(
        modifier =
            GlanceModifier
                .fillMaxSize()
                .clickable(open)
                .padding(14.dp),
        horizontalAlignment = Alignment.Start,
        verticalAlignment = Alignment.Top,
    ) {
        Text(
            text = "1 YEAR AGO",
            style = textStyle(style, ColorProvider(Color(0x8CFFFFFF)), 10, FontWeight.Bold),
        )
        Spacer(GlanceModifier.height(6.dp))
        Text(
            text = "You + ${data.senderName.ifBlank { "Jay" }}",
            maxLines = 1,
            style = textStyle(style, ColorProvider(Color.White), 14, FontWeight.Bold),
        )
        Spacer(GlanceModifier.defaultWeight())
        Box(
            modifier =
                GlanceModifier
                    .fillMaxWidth()
                    .height(72.dp)
                    .cornerRadius(10.dp),
            contentAlignment = Alignment.BottomStart,
        ) {
            Image(
                provider = ImageProvider(bitmap),
                contentDescription = "Memory",
                modifier =
                    GlanceModifier
                        .fillMaxSize()
                        .cornerRadius(10.dp),
                contentScale = ContentScale.Crop,
            )
            Text(
                text = "Relive →",
                modifier = GlanceModifier.padding(8.dp),
                style = textStyle(style, ColorProvider(Color.White), 10, FontWeight.Bold),
            )
        }
    }
}

private fun openMomentAction(data: MomentWidgetData) =
    if (data.momentId.isNotEmpty()) {
        actionStartActivity(launchDeepLink("moment/${data.momentId}"))
    } else {
        actionStartActivity(launchMainActivityIntent())
    }

@Composable
private fun PendingMomentLayout(
    data: MomentWidgetData,
    style: WidgetThemeStyle,
    liveTime: String,
) {
    val open = openMomentAction(data)
    val name = data.senderName.ifBlank { "a friend" }
    val time = if (data.showTimestamp && liveTime.isNotBlank()) liveTime else data.relativeTime

    Column(
        modifier =
            GlanceModifier
                .fillMaxSize()
                .clickable(open)
                .padding(18.dp),
        horizontalAlignment = Alignment.Start,
        verticalAlignment = Alignment.Bottom,
    ) {
        Text(
            text = data.headerEmoji.ifBlank { WidgetThemeStyles.themeEmoji(data.theme) } + "  NEW MOMENT",
            style = textStyle(style, style.accentColor, 10, FontWeight.Bold),
        )
        Spacer(GlanceModifier.height(8.dp))
        Text(
            text = "From $name",
            maxLines = 2,
            style = textStyle(style, style.labelColor, 16, FontWeight.Bold),
        )
        if (time.isNotBlank()) {
            Spacer(GlanceModifier.height(4.dp))
            Text(
                text = time,
                style = textStyle(style, style.secondaryColor, 12),
            )
        }
        Spacer(GlanceModifier.height(10.dp))
        Text(
            text = "Tap to open",
            style = textStyle(style, style.accentColor, 10, FontWeight.Bold),
        )
    }
}

@Composable
private fun EmptyWidgetLayout(data: MomentWidgetData, style: WidgetThemeStyle) {
    val openApp = actionStartActivity(launchMainActivityIntent())
    val openCamera = actionStartActivity(launchDeepLink("camera"))

    Column(
        modifier =
            GlanceModifier
                .fillMaxSize()
                .clickable(openApp)
                .padding(18.dp),
        horizontalAlignment = Alignment.Start,
        verticalAlignment = Alignment.Bottom,
    ) {
        Text(
            text = "MOMENT",
            style = textStyle(style, style.accentColor, 10, FontWeight.Bold),
        )
        Spacer(GlanceModifier.height(6.dp))
        Text(
            text = "Waiting for a new moment",
            style = textStyle(style, style.labelColor, 14, FontWeight.Bold),
        )
        Spacer(GlanceModifier.height(4.dp))
        Text(
            text = modeHint(data.widgetMode),
            style = textStyle(style, style.secondaryColor, 12),
        )
        Spacer(GlanceModifier.height(14.dp))
        Text(
            text = "OPEN CAMERA",
            modifier = GlanceModifier.clickable(openCamera),
            style = textStyle(style, style.accentColor, 10, FontWeight.Bold),
        )
    }
}

private fun modeHint(widgetMode: String): String =
    when (widgetMode) {
        "circle" -> "From your circle"
        "person" -> "From one person"
        else -> "Latest from friends"
    }

private fun textStyle(
    style: WidgetThemeStyle,
    color: ColorProvider,
    size: Int,
    weight: FontWeight = FontWeight.Medium,
): TextStyle =
    TextStyle(
        color = color,
        fontSize = size.sp,
        fontWeight = weight,
        fontFamily = style.fontFamily,
    )
