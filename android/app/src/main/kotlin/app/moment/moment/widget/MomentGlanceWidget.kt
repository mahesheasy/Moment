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
import androidx.glance.LocalContext
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionRunCallback
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
import app.moment.moment.R
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

        val grid =
            withContext(Dispatchers.IO) {
                try {
                    loadWidgetGrid(context)
                } catch (error: Exception) {
                    Log.e(TAG, "Failed to load widget grid", error)
                    emptyList()
                }
            }

        val bitmap = grid.firstOrNull()?.bitmap

        val avatarBitmap =
            withContext(Dispatchers.IO) {
                try {
                    val avatarPath =
                        grid.firstOrNull()?.entry?.avatarPath ?: data.avatarPath
                    if (avatarPath != null) {
                        WidgetBitmap.decode(avatarPath)
                    } else {
                        null
                    }
                } catch (error: Exception) {
                    Log.e(TAG, "Failed to decode widget avatar", error)
                    null
                }
            }

        val displayData = resolveDisplayData(data, grid)

        provideContent {
            MomentWidgetContent(
                data = displayData,
                bitmap = bitmap,
                avatarBitmap = avatarBitmap,
                grid = grid,
            )
        }
    }

    companion object {
        private const val TAG = "MomentGlanceWidget"
    }
}

/** Labels / deep links follow the first grid cell, not stale legacy prefs. */
private fun resolveDisplayData(
    base: MomentWidgetData,
    grid: List<WidgetGridCell>,
): MomentWidgetData {
    val front = grid.firstOrNull()?.entry ?: return base
    return base.copy(
        hasMoment = true,
        momentId = front.momentId,
        senderName = front.senderName,
        senderId = front.senderId,
        imagePath = front.imagePath,
        avatarPath = front.avatarPath,
        caption = front.caption,
        createdAtMillis = front.createdAtMillis,
        relativeTime = front.relativeTime,
        isUnread = front.isUnread,
    )
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
        displaySize = "small",
        privacyMode = "full",
        showSender = true,
        showTimestamp = true,
        showCaptions = false,
        lockScreenPrivacy = true,
        paused = false,
        recentIndex = 0,
        recentCount = 0,
        showStreak = true,
        streakCount = 0,
        renderSeq = 0L,
    )

private fun widgetImageKey(momentId: String, renderSeq: Long): String =
    "moment-$momentId-$renderSeq"

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
    grid: List<WidgetGridCell> = emptyList(),
) {
    val style = WidgetThemeStyles.resolve(data.theme, data.accentColor, data.typography)
    val liveTime =
        WidgetRelativeTime.format(data.createdAtMillis).ifBlank { data.relativeTime }

    Box(
        modifier =
            GlanceModifier
                .fillMaxSize()
                .background(ColorProvider(Color(0xFF0A0A0B)))
                .cornerRadius(20.dp),
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
            grid.isNotEmpty() -> {
                val cell = grid.first()
                val cellData = data.copy(isUnread = cell.entry.isUnread)
                when (cell.renderMode) {
                    WidgetRenderMode.LOCKED_PLACEHOLDER ->
                        SafePlaceholderLayout(
                            style = style,
                            open = openMomentAction(cellData),
                        )
                    WidgetRenderMode.PRIVATE ->
                        PrivateMomentLayout(
                            title = "New Moment",
                            from = "From ${cellData.senderName.ifBlank { "a friend" }}",
                            action = "Tap to reveal",
                            style = style,
                            open = openMomentAction(cellData),
                        )
                    WidgetRenderMode.BLUR ->
                        if (bitmap != null) {
                            BlurMomentLayout(
                                data = cellData,
                                bitmap = bitmap,
                                style = style,
                                liveTime = liveTime,
                            )
                        } else {
                            LocketPendingLayout(
                                data = cellData,
                                style = style,
                                avatarBitmap = avatarBitmap,
                                liveTime = liveTime,
                            )
                        }
                    WidgetRenderMode.FULL ->
                        if (bitmap != null) {
                            FullMomentLayout(
                                data = cellData,
                                bitmap = bitmap,
                                avatarBitmap = avatarBitmap,
                                style = style,
                                liveTime = liveTime,
                            )
                        } else {
                            LocketPendingLayout(
                                data = cellData,
                                style = style,
                                avatarBitmap = avatarBitmap,
                                liveTime = liveTime,
                            )
                        }
                    WidgetRenderMode.PAUSED ->
                        PrivateMomentLayout(
                            title = "Widget paused",
                            from = data.senderName.ifBlank { "Moment" },
                            action = "Tap to resume",
                            style = style,
                            open = actionStartActivity(launchMainActivityIntent()),
                        )
                }
            }
            data.hasMoment && bitmap == null ->
                LocketPendingLayout(
                    data = data,
                    style = style,
                    avatarBitmap = avatarBitmap,
                    liveTime = liveTime,
                )
            data.hasMoment ->
                PendingMomentLayout(
                    data = data,
                    style = style,
                    liveTime = liveTime,
                )
            else ->
                LocketEmptyLayout(
                    data = data,
                    style = style,
                    avatarBitmap = avatarBitmap,
                )
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
    val context = LocalContext.current
    val open =
        fullMomentRevealAction(context, data.momentId, data.imagePath)
            ?: openMomentAction(data)
    val name = data.senderName.ifBlank { "a friend" }
    val parsed = WidgetCaptionParser.parse(data.caption)
    val momentStreak = WidgetCaptionParser.streakCountFromCaption(data.caption)
    val scale = layoutScale(data.displaySize, parsed)
    val showUserCaption = data.showCaptions && parsed.userCaption.isNotBlank()
    val showBottomBar =
        data.showSender ||
            (data.showTimestamp && liveTime.isNotBlank()) ||
            showUserCaption

    Box(
        modifier =
            GlanceModifier
                .fillMaxSize()
                .clickable(open),
        contentAlignment = Alignment.TopStart,
    ) {
        Image(
            provider = ImageProvider(bitmap),
            contentDescription = widgetImageKey(data.momentId, data.renderSeq),
            modifier = GlanceModifier.fillMaxSize(),
            contentScale = ContentScale.Crop,
        )
        WidgetMomentOverlays(parsed = parsed)
        if (data.isUnread) {
            Box(
                modifier =
                    GlanceModifier
                        .padding(8.dp)
                        .width(8.dp)
                        .height(8.dp)
                        .background(ColorProvider(Color(0xFFFF6B8A)))
                        .cornerRadius(4.dp),
            ) {}
        }
        if (showBottomBar) {
            Box(
                modifier = GlanceModifier.fillMaxSize(),
                contentAlignment = Alignment.BottomStart,
            ) {
                Box(
                    modifier =
                        GlanceModifier
                            .fillMaxWidth()
                            .height(scale.overlayHeight.dp)
                            .background(ColorProvider(Color(0xA6000000))),
                ) {}
                Column(
                    modifier =
                        GlanceModifier
                            .fillMaxWidth()
                            .padding(horizontal = scale.pad.dp, vertical = 6.dp),
                ) {
                    if (showUserCaption) {
                        Text(
                            text = parsed.userCaption,
                            maxLines = 2,
                            style = textStyle(
                                style,
                                ColorProvider(Color.White),
                                scale.captionSize,
                                FontWeight.Bold,
                            ),
                        )
                        if (data.showSender || (data.showTimestamp && liveTime.isNotBlank())) {
                            Spacer(GlanceModifier.height(4.dp))
                        }
                    }
                    Row(
                        modifier = GlanceModifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Column(modifier = GlanceModifier.defaultWeight()) {
                            if (data.showSender) {
                                Text(
                                    text = name,
                                    maxLines = 1,
                                    style = textStyle(
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
                                    style = textStyle(
                                        style,
                                        ColorProvider(Color(0xCCFFFFFF)),
                                        scale.timeSize,
                                        FontWeight.Medium,
                                    ),
                                )
                            }
                        }
                    }
                }
            }
        }
        if (momentStreak != null) {
            Box(
                modifier = GlanceModifier.fillMaxSize(),
                contentAlignment = Alignment.TopEnd,
            ) {
                Box(modifier = GlanceModifier.padding(6.dp)) {
                    WidgetStreakBadge(count = momentStreak, compact = true)
                }
            }
        }
        WidgetCycleTapZones(enabled = data.recentCount > 1)
    }
}

private val locketRingColor = Color(0xFFF5C518)

@Composable
private fun WidgetStreakBadge(count: Int, compact: Boolean = true) {
    Box(
        modifier =
            GlanceModifier
                .background(ColorProvider(Color(0x73000000)))
                .cornerRadius(999.dp)
                .padding(
                    horizontal = if (compact) 9.dp else 10.dp,
                    vertical = if (compact) 5.dp else 6.dp,
                ),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = "🔥 $count",
            style =
                TextStyle(
                    color = ColorProvider(locketRingColor),
                    fontSize = if (compact) 11.sp else 12.sp,
                    fontWeight = FontWeight.Bold,
                ),
        )
    }
}

private data class WidgetLayoutScale(
    val overlayHeight: Int,
    val nameSize: Int,
    val timeSize: Int,
    val captionSize: Int,
    val headerSize: Int,
    val pad: Int,
)

private fun layoutScale(
    displaySize: String,
    parsed: ParsedMomentCaption = ParsedMomentCaption(),
): WidgetLayoutScale {
    val base =
        when (displaySize) {
            "small" -> WidgetLayoutScale(48, 11, 9, 10, 9, 6)
            "medium" -> WidgetLayoutScale(58, 12, 10, 11, 10, 8)
            else -> WidgetLayoutScale(72, 14, 11, 12, 11, 10)
        }
    val captionBoost =
        if (parsed.userCaption.isNotBlank()) {
            if (parsed.userCaption.length > 28) 22 else 14
        } else {
            0
        }
    return base.copy(overlayHeight = base.overlayHeight + captionBoost)
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
    val momentStreak = WidgetCaptionParser.streakCountFromCaption(data.caption)
    val scale = layoutScale(data.displaySize)
    val showBottomBar =
        data.showSender || (data.showTimestamp && liveTime.isNotBlank())

    Box(
        modifier =
            GlanceModifier
                .fillMaxSize()
                .clickable(open),
        contentAlignment = Alignment.TopStart,
    ) {
        Image(
            provider = ImageProvider(bitmap),
            contentDescription = "Hidden moment from ${data.senderName}",
            modifier = GlanceModifier.fillMaxSize(),
            contentScale = ContentScale.Crop,
        )
        Box(
            modifier =
                GlanceModifier
                    .fillMaxSize()
                    .background(ColorProvider(Color(0x55000000))),
        ) {}
        if (showBottomBar) {
            Box(
                modifier = GlanceModifier.fillMaxSize(),
                contentAlignment = Alignment.BottomStart,
            ) {
                Box(
                    modifier =
                        GlanceModifier
                            .fillMaxWidth()
                            .height(scale.overlayHeight.dp)
                            .background(ColorProvider(Color(0xCC000000))),
                ) {}
                Column(
                    modifier =
                        GlanceModifier
                            .fillMaxWidth()
                            .padding(horizontal = scale.pad.dp, vertical = 6.dp),
                ) {
                    if (data.showSender) {
                        Text(
                            text = name,
                            maxLines = 1,
                            style = textStyle(
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
                            style = textStyle(
                                style,
                                ColorProvider(Color(0xCCFFFFFF)),
                                scale.timeSize,
                            ),
                        )
                    }
                }
            }
        }
        if (momentStreak != null) {
            Box(
                modifier = GlanceModifier.fillMaxSize(),
                contentAlignment = Alignment.TopEnd,
            ) {
                Box(modifier = GlanceModifier.padding(6.dp)) {
                    WidgetStreakBadge(count = momentStreak, compact = true)
                }
            }
        }
    }
}

/** Safe placeholder when the device is locked and lock-screen privacy is enabled. */
@Composable
private fun SafePlaceholderLayout(
    style: WidgetThemeStyle,
    open: androidx.glance.action.Action,
) {
    PrivateMomentLayout(
        title = "New Moment",
        from = "Unlock to view",
        action = "Tap to open Moment",
        style = style,
        open = open,
    )
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
        actionRunCallback<WidgetOpenMomentAction>(
            actionParametersOf(WidgetOpenMomentAction.MomentIdKey to data.momentId),
        )
    } else {
        actionStartActivity(launchMainActivityIntent())
    }

private fun fullMomentRevealAction(
    context: Context,
    momentId: String,
    imagePath: String?,
): androidx.glance.action.Action? {
    if (momentId.isBlank() || imagePath.isNullOrBlank()) return null
    return actionStartActivity(
        WidgetRevealActivity.launchIntent(context, momentId, imagePath),
    )
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

private val locketAccent = Color(0xFFFF6B8A)
private val locketMuted = Color(0xFF8E8E93)

@Composable
private fun LocketPendingLayout(
    data: MomentWidgetData,
    style: WidgetThemeStyle,
    avatarBitmap: Bitmap?,
    liveTime: String,
) {
    val open = openMomentAction(data)
    val name = data.senderName.ifBlank { "a friend" }
    val time = if (data.showTimestamp && liveTime.isNotBlank()) liveTime else data.relativeTime

    Box(
        modifier =
            GlanceModifier
                .fillMaxSize()
                .background(ColorProvider(Color(0xFF0A0A0B)))
                .clickable(open),
        contentAlignment = Alignment.TopStart,
    ) {
        Box(
            modifier = GlanceModifier.padding(10.dp),
            contentAlignment = Alignment.Center,
        ) {
            LocketMiniAvatar(
                avatarBitmap = avatarBitmap,
                style = style,
                size = 30,
            )
        }
        Column(
            modifier = GlanceModifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = "✨",
                style = textStyle(style, ColorProvider(Color(0xCCFFFFFF)), 20),
            )
            Spacer(GlanceModifier.height(6.dp))
            Text(
                text = "New moment",
                style = textStyle(
                    style,
                    ColorProvider(Color(0xCCFFFFFF)),
                    13,
                    FontWeight.Medium,
                ),
            )
            Spacer(GlanceModifier.height(3.dp))
            Text(
                text = "From $name",
                maxLines = 2,
                style = textStyle(style, ColorProvider(locketMuted), 10, FontWeight.Medium),
            )
            if (time.isNotBlank()) {
                Spacer(GlanceModifier.height(2.dp))
                Text(
                    text = time,
                    style = textStyle(style, ColorProvider(locketMuted), 9, FontWeight.Medium),
                )
            }
        }
    }
}

@Composable
private fun LocketEmptyLayout(
    data: MomentWidgetData,
    style: WidgetThemeStyle,
    avatarBitmap: Bitmap?,
) {
    val openCamera = actionStartActivity(launchDeepLink("camera"))

    Box(
        modifier =
            GlanceModifier
                .fillMaxSize()
                .background(ColorProvider(Color.Black))
                .clickable(openCamera),
        contentAlignment = Alignment.Center,
    ) {
        Image(
            provider = ImageProvider(WidgetEmptyStateImages.drawableRes()),
            contentDescription = "No Moments Yet",
            modifier = GlanceModifier.fillMaxSize(),
            contentScale = ContentScale.Crop,
        )
    }
}

@Composable
private fun WidgetCycleTapZones(enabled: Boolean) {
    if (!enabled) return
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

@Composable
private fun LocketPhotoLayout(
    data: MomentWidgetData,
    bitmap: Bitmap,
    style: WidgetThemeStyle,
) {
    val open = openMomentAction(data)
    val liveTime =
        WidgetRelativeTime.format(data.createdAtMillis).ifBlank { data.relativeTime }
    val sender = data.senderName.ifBlank { "Friend" }
    val parsed = WidgetCaptionParser.parse(data.caption)
    val momentStreak = WidgetCaptionParser.streakCountFromCaption(data.caption)
    val showUserCaption = data.showCaptions && parsed.userCaption.isNotBlank()

    Box(
        modifier =
            GlanceModifier
                .fillMaxSize()
                .clickable(open),
        contentAlignment = Alignment.TopStart,
    ) {
        Image(
            provider = ImageProvider(bitmap),
            contentDescription = "Moment from $sender",
            modifier = GlanceModifier.fillMaxSize(),
            contentScale = ContentScale.Crop,
        )
        WidgetMomentOverlays(parsed = parsed)
        Box(
            modifier = GlanceModifier.fillMaxSize(),
            contentAlignment = Alignment.BottomStart,
        ) {
            Box(
                modifier =
                    GlanceModifier
                        .fillMaxWidth()
                        .height((if (showUserCaption) 64 else 52).dp)
                        .background(ColorProvider(Color(0xA6000000))),
            ) {}
            Column(
                modifier =
                    GlanceModifier
                        .fillMaxWidth()
                        .padding(horizontal = 10.dp, vertical = 6.dp),
            ) {
                if (showUserCaption) {
                    Text(
                        text = parsed.userCaption,
                        maxLines = 2,
                        style = textStyle(
                            style,
                            ColorProvider(Color.White),
                            11,
                            FontWeight.Bold,
                        ),
                    )
                    Spacer(GlanceModifier.height(4.dp))
                }
                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(modifier = GlanceModifier.defaultWeight()) {
                        if (data.showSender) {
                            Text(
                                text = sender,
                                maxLines = 1,
                                style = textStyle(
                                    style,
                                    ColorProvider(Color.White),
                                    13,
                                    FontWeight.Bold,
                                ),
                            )
                        }
                        if (data.showTimestamp && liveTime.isNotBlank()) {
                            Text(
                                text = liveTime,
                                style = textStyle(
                                    style,
                                    ColorProvider(Color(0xCCFFFFFF)),
                                    10,
                                    FontWeight.Medium,
                                ),
                            )
                        }
                    }
                    if (momentStreak != null) {
                        WidgetStreakBadge(count = momentStreak)
                    }
                }
            }
        }
    }
}

@Composable
private fun LocketMiniAvatar(
    avatarBitmap: Bitmap?,
    style: WidgetThemeStyle,
    size: Int,
) {
    val inner = (size - 4).dp
    Box(
        modifier =
            GlanceModifier
                .width(size.dp)
                .height(size.dp)
                .background(ColorProvider(Color(0x33FFFFFF)))
                .cornerRadius((size / 2).dp),
        contentAlignment = Alignment.Center,
    ) {
        if (avatarBitmap != null) {
            Image(
                provider = ImageProvider(avatarBitmap),
                contentDescription = "Avatar",
                modifier =
                    GlanceModifier
                        .width(inner)
                        .height(inner)
                        .cornerRadius((size / 2 - 2).dp),
                contentScale = ContentScale.Crop,
            )
        } else {
            Box(
                modifier =
                    GlanceModifier
                        .width(inner)
                        .height(inner)
                        .background(ColorProvider(Color(0xFF1C1C1E)))
                        .cornerRadius((size / 2 - 2).dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = "♡",
                    style = textStyle(
                        style,
                        ColorProvider(locketAccent),
                        12,
                        FontWeight.Bold,
                    ),
                )
            }
        }
    }
}

@Composable
private fun LocketBlurLayout(
    data: MomentWidgetData,
    bitmap: Bitmap,
    style: WidgetThemeStyle,
) {
    val open = openMomentAction(data)

    Box(
        modifier =
            GlanceModifier
                .fillMaxSize()
                .clickable(open),
        contentAlignment = Alignment.Center,
    ) {
        Image(
            provider = ImageProvider(bitmap),
            contentDescription = "Hidden moment",
            modifier = GlanceModifier.fillMaxSize(),
            contentScale = ContentScale.Crop,
        )
        Box(
            modifier =
                GlanceModifier
                    .fillMaxSize()
                    .background(ColorProvider(Color(0x88000000))),
        ) {}
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = "♡",
                style = textStyle(style, ColorProvider(Color.White), 24, FontWeight.Bold),
            )
            Spacer(GlanceModifier.height(6.dp))
            Text(
                text = "New moment",
                style = textStyle(style, ColorProvider(Color.White), 13, FontWeight.Bold),
            )
        }
    }
}

@Composable
private fun LocketPrivateLayout(
    data: MomentWidgetData,
    style: WidgetThemeStyle,
) {
    val open = openMomentAction(data)

    Box(
        modifier =
            GlanceModifier
                .fillMaxSize()
                .clickable(open),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            LocketMiniAvatar(avatarBitmap = null, style = style, size = 40)
            Spacer(GlanceModifier.height(10.dp))
            Text(
                text = "Tap to reveal",
                style = textStyle(style, ColorProvider(Color.White), 13, FontWeight.Bold),
            )
        }
    }
}

@Composable
private fun EmptyWidgetLayout(data: MomentWidgetData, style: WidgetThemeStyle) {
    LocketEmptyLayout(data = data, style = style, avatarBitmap = null)
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
