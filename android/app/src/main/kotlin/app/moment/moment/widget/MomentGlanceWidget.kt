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

        val stack =
            withContext(Dispatchers.IO) {
                try {
                    loadWidgetStack(context)
                } catch (error: Exception) {
                    Log.e(TAG, "Failed to load widget stack", error)
                    emptyList()
                }
            }

        val bitmap = stack.firstOrNull()?.bitmap

        val avatarBitmap =
            withContext(Dispatchers.IO) {
                try {
                    val avatarPath =
                        stack.firstOrNull()?.entry?.avatarPath ?: data.avatarPath
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

        val displayData = resolveDisplayData(data, stack)

        provideContent {
            MomentWidgetContent(
                data = displayData,
                bitmap = bitmap,
                avatarBitmap = avatarBitmap,
                stack = stack,
            )
        }
    }

    companion object {
        private const val TAG = "MomentGlanceWidget"
    }
}

/** Labels / deep links always follow the front stack card, not stale legacy prefs. */
private fun resolveDisplayData(
    base: MomentWidgetData,
    stack: List<WidgetStackCard>,
): MomentWidgetData {
    val front = stack.firstOrNull()?.entry ?: return base
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
    )
}

private fun loadWidgetStack(context: Context): List<WidgetStackCard> {
    val queue = WidgetMomentQueue.loadQueue(context)
    if (queue.isEmpty()) return emptyList()

    val (index, _) = WidgetMomentQueue.queueMeta(context)
    val depthCount = minOf(3, queue.size - index)
    val patches = mutableListOf<WidgetMomentEntry>()

    val cards =
        (0 until depthCount).map { offset ->
            val raw = queue[index + offset]
            val entry = WidgetImageResolver.ensureCached(context, raw)
            if (entry != raw) patches.add(entry)
            val decoded = WidgetBitmap.decode(entry.imagePath)
            val privacyMode = WidgetPrivacyResolver.resolve(context, entry.senderId)
            val bitmap =
                decoded?.let { source ->
                    when {
                        offset > 0 -> WidgetBitmap.blur(source)
                        privacyMode == "blur" -> WidgetBitmap.blur(source)
                        privacyMode == "private" -> source
                        else ->
                            resolveWidgetMomentBitmap(
                                source = source,
                                privacyMode = privacyMode,
                                context = context,
                                momentId = entry.momentId,
                            )
                    }
                }
            WidgetStackCard(entry = entry, bitmap = bitmap, depth = offset)
        }

    if (patches.isNotEmpty()) {
        WidgetMomentQueue.patchEntries(context, patches)
    }
    return cards
}

/** Applies user privacy mode + per-view progressive preview blur to widget media. */
internal fun resolveWidgetMomentBitmap(
    source: Bitmap,
    privacyMode: String,
    context: Context,
    momentId: String,
): Bitmap {
    if (privacyMode == "blur") {
        return WidgetBitmap.blur(source)
    }
    if (privacyMode == "private") {
        return source
    }
    return when (
        val progress = WidgetMediaPrivacyPreview.previewProgress(context, momentId)
    ) {
        0f -> source
        1f -> WidgetBitmap.blur(source)
        else -> WidgetBitmap.blur(source, progress)
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
    stack: List<WidgetStackCard> = emptyList(),
) {
    val style = WidgetThemeStyles.resolve(data.theme, data.accentColor, data.typography)
    val liveTime =
        WidgetRelativeTime.format(data.createdAtMillis).ifBlank { data.relativeTime }
    val compact = data.displaySize != "large"

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
            compact && data.theme == "memory" && bitmap != null ->
                LocketStackLayout(
                    data = data,
                    bitmap = bitmap,
                    stack = stack,
                    style = style,
                )
            compact && data.privacyMode == "private" && data.hasMoment ->
                LocketPrivateLayout(
                    data = data,
                    style = style,
                )
            compact && bitmap != null && data.privacyMode == "blur" ->
                LocketStackLayout(
                    data = data,
                    bitmap = bitmap,
                    stack = stack,
                    style = style,
                    blurred = true,
                )
            compact && bitmap != null ->
                LocketStackLayout(
                    data = data,
                    bitmap = bitmap,
                    stack = stack,
                    style = style,
                )
            compact && data.hasMoment && bitmap == null ->
                LocketPendingLayout(
                    data = data,
                    style = style,
                    avatarBitmap = avatarBitmap,
                    liveTime = liveTime,
                )
            compact ->
                LocketEmptyLayout(
                    data = data,
                    style = style,
                    avatarBitmap = avatarBitmap,
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
                    stack = stack,
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
    stack: List<WidgetStackCard> = emptyList(),
) {
    val open = openMomentAction(data)
    val name = if (data.showSender) data.senderName.ifBlank { "Moment" } else ""
    val scale = layoutScale(data.displaySize)
    val accent = WidgetThemeStyles.parseAccent(data.accentColor)
    val scrim = WidgetThemeStyles.photoScrim(data.theme, accent)
    val headerEmoji =
        data.headerEmoji.ifBlank { WidgetThemeStyles.themeEmoji(data.theme) }
    val showThemeHeader =
        data.theme != "minimal" && headerEmoji.isNotBlank() && data.theme != "memory"

    Box(
        modifier = GlanceModifier.fillMaxSize(),
        contentAlignment = Alignment.TopStart,
    ) {
        stack
            .asReversed()
            .drop(1)
            .forEach { card ->
                WidgetBehindCard(card = card)
            }
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
        Box(
            modifier =
                GlanceModifier
                    .fillMaxSize()
                    .background(ColorProvider(accent.copy(alpha = 0.12f))),
        ) {}
        if (showThemeHeader) {
            Row(
                modifier =
                    GlanceModifier
                        .fillMaxWidth()
                        .padding(scale.pad.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(
                    modifier =
                        GlanceModifier
                            .background(ColorProvider(Color(0x99000000)))
                            .cornerRadius(10.dp)
                            .padding(horizontal = 8.dp, vertical = 6.dp),
                ) {
                    Text(
                        text = headerEmoji,
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
            }
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
                if (data.showStreak && data.streakCount > 0) {
                    WidgetStreakBadge(count = data.streakCount, compact = false)
                }
            }
        }
        WidgetCycleTapZones(enabled = data.recentCount > 1)
        }
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
                            text = liveTime,
                            modifier = GlanceModifier.padding(top = 2.dp),
                            style = textStyle(style, ColorProvider(Color(0xCCFFFFFF)), 12),
                        )
                    }
                }
                if (data.showStreak && data.streakCount > 0) {
                    WidgetStreakBadge(count = data.streakCount)
                }
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
    val openApp = actionStartActivity(launchMainActivityIntent())

    Box(
        modifier =
            GlanceModifier
                .fillMaxSize()
                .background(ColorProvider(Color(0xFF0A0A0B)))
                .clickable(openApp),
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
                text = "📷",
                style = textStyle(style, ColorProvider(Color(0x55FFFFFF)), 22),
            )
            Spacer(GlanceModifier.height(8.dp))
            Text(
                text = "No pics yet",
                style = textStyle(
                    style,
                    ColorProvider(Color(0xCCFFFFFF)),
                    13,
                    FontWeight.Medium,
                ),
            )
            Spacer(GlanceModifier.height(3.dp))
            Text(
                text = "Moments appear here",
                style = textStyle(
                    style,
                    ColorProvider(locketMuted),
                    10,
                    FontWeight.Medium,
                ),
            )
        }
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
private fun WidgetBehindCard(card: WidgetStackCard) {
    val depth = card.depth.coerceAtLeast(1)
    val insetStart = (depth * 10).dp
    val insetEnd = (depth * 4).dp
    val insetTop = (depth * 8).dp
    val insetBottom = (depth * 14).dp
    val radius = (18 - depth).coerceAtLeast(14).dp
    val sender = card.entry.senderName.ifBlank { "Friend" }

    Box(
        modifier =
            GlanceModifier
                .fillMaxSize()
                .padding(
                    start = insetStart,
                    end = insetEnd,
                    top = insetTop,
                    bottom = insetBottom,
                )
                .cornerRadius(radius)
                .background(ColorProvider(Color(0xFF121214))),
        contentAlignment = Alignment.TopStart,
    ) {
        if (card.bitmap != null) {
            Image(
                provider = ImageProvider(card.bitmap),
                contentDescription = widgetImageKey(card.entry.momentId, 0L),
                modifier = GlanceModifier.fillMaxSize(),
                contentScale = ContentScale.Crop,
            )
        }
        Box(
            modifier =
                GlanceModifier
                    .fillMaxSize()
                    .background(ColorProvider(Color(0x73000000))),
        ) {}
        Box(
            modifier = GlanceModifier.fillMaxSize(),
            contentAlignment = Alignment.BottomStart,
        ) {
            Box(
                modifier =
                    GlanceModifier
                        .fillMaxWidth()
                        .height(36.dp)
                        .background(ColorProvider(Color(0x99000000))),
            ) {}
            Text(
                text = sender,
                maxLines = 1,
                modifier = GlanceModifier.padding(horizontal = 8.dp, vertical = 6.dp),
                style =
                    textStyle(
                        WidgetThemeStyles.resolve("minimal", "#FF6B8A", "default"),
                        ColorProvider(Color(0xCCFFFFFF)),
                        10,
                        FontWeight.Medium,
                    ),
            )
        }
    }
}

@Composable
private fun LocketStackLayout(
    data: MomentWidgetData,
    bitmap: Bitmap,
    stack: List<WidgetStackCard>,
    style: WidgetThemeStyle,
    blurred: Boolean = false,
) {
    val front = stack.firstOrNull()?.entry
    val momentId = front?.momentId ?: data.momentId
    val open =
        if (momentId.isNotEmpty()) {
            actionStartActivity(launchDeepLink("moment/$momentId"))
        } else {
            actionStartActivity(launchMainActivityIntent())
        }
    val createdAt = front?.createdAtMillis ?: data.createdAtMillis
    val liveTime =
        WidgetRelativeTime.format(createdAt).ifBlank {
            front?.relativeTime ?: data.relativeTime
        }
    val sender = (front?.senderName ?: data.senderName).ifBlank { "Friend" }

    Box(
        modifier = GlanceModifier.fillMaxSize(),
        contentAlignment = Alignment.TopStart,
    ) {
        stack
            .asReversed()
            .drop(1)
            .forEach { card ->
                WidgetBehindCard(card = card)
            }
        Box(
            modifier =
                GlanceModifier
                    .fillMaxSize()
                    .clickable(open),
            contentAlignment = Alignment.TopStart,
        ) {
            Image(
                provider = ImageProvider(bitmap),
                contentDescription = widgetImageKey(momentId, data.renderSeq),
                modifier = GlanceModifier.fillMaxSize(),
                contentScale = ContentScale.Crop,
            )
            if (blurred) {
                Box(
                    modifier =
                        GlanceModifier
                            .fillMaxSize()
                            .background(ColorProvider(Color(0x66000000))),
                ) {}
            }
            Box(
                modifier = GlanceModifier.fillMaxSize(),
                contentAlignment = Alignment.BottomStart,
            ) {
                Box(
                    modifier =
                        GlanceModifier
                            .fillMaxWidth()
                            .height(52.dp)
                            .background(ColorProvider(Color(0xA6000000))),
                ) {}
                Row(
                    modifier =
                        GlanceModifier
                            .fillMaxWidth()
                            .padding(horizontal = 10.dp, vertical = 8.dp),
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
                    if (data.showStreak && data.streakCount > 0) {
                        WidgetStreakBadge(count = data.streakCount)
                    }
                }
            }
        }
        WidgetCycleTapZones(enabled = data.recentCount > 1)
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
        Box(
            modifier = GlanceModifier.fillMaxSize(),
            contentAlignment = Alignment.BottomStart,
        ) {
            Box(
                modifier =
                    GlanceModifier
                        .fillMaxWidth()
                        .height(52.dp)
                        .background(ColorProvider(Color(0xA6000000))),
            ) {}
            Row(
                modifier =
                    GlanceModifier
                        .fillMaxWidth()
                        .padding(horizontal = 10.dp, vertical = 8.dp),
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
                if (data.showStreak && data.streakCount > 0) {
                    WidgetStreakBadge(count = data.streakCount)
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
