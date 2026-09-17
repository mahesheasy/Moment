package app.moment.moment.widget

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.LocalContext
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.Action
import androidx.glance.action.clickable
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.action.actionParametersOf
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

fun loadWidgetGrid(context: Context): List<WidgetGridCell> {
    val active = WidgetMomentQueue.activeEntry(context) ?: return emptyList()
    val patches = mutableListOf<WidgetMomentEntry>()

    val entry = WidgetImageResolver.ensureCached(context, active)
    if (entry != active) patches.add(entry)
    val privacyMode = WidgetPrivacyResolver.resolve(context, entry.senderId)
    val decoded = WidgetBitmap.decode(entry.imagePath)
    val bitmap =
        decoded?.let { source ->
            resolveWidgetDisplayBitmap(
                source = source,
                privacyMode = privacyMode,
                isUnread = entry.isUnread,
            )
        }
    val cell = WidgetGridCell(entry = entry, bitmap = bitmap, privacyMode = privacyMode)

    if (patches.isNotEmpty()) {
        WidgetMomentQueue.patchEntries(context, patches)
    }
    return listOf(cell)
}

/** Unread moments stay blurred; seen moments show the clear photo (Full + Blur modes). */
fun resolveWidgetDisplayBitmap(
    source: Bitmap,
    privacyMode: String,
    isUnread: Boolean,
): Bitmap {
    if (privacyMode == "private") return source
    if (!isUnread) return source
    return WidgetBitmap.blur(source)
}

/** @deprecated Use [resolveWidgetDisplayBitmap]. */
fun resolveWidgetMomentBitmap(
    source: Bitmap,
    privacyMode: String,
    context: Context,
    momentId: String,
): Bitmap = resolveWidgetDisplayBitmap(source, privacyMode, isUnread = true)

@Composable
fun WidgetGridLayout(
    data: MomentWidgetData,
    cells: List<WidgetGridCell>,
    style: WidgetThemeStyle,
) {
    when (cells.size) {
        0 -> Unit
        1 -> WidgetGridSingleCell(data = data, cell = cells.first(), style = style)
        2 -> WidgetGridRow(data = data, cells = cells, style = style)
        3 -> WidgetGridThreeCells(data = data, cells = cells, style = style)
        else -> WidgetGridFourCells(data = data, cells = cells, style = style)
    }
    if (data.recentCount > 1) {
        WidgetCycleTapZones(enabled = true)
    }
}

@Composable
private fun WidgetGridSingleCell(
    data: MomentWidgetData,
    cell: WidgetGridCell,
    style: WidgetThemeStyle,
) {
    WidgetGridCellContent(
        data = data,
        cell = cell,
        style = style,
        modifier = GlanceModifier.fillMaxSize(),
    )
}

@Composable
private fun WidgetGridRow(
    data: MomentWidgetData,
    cells: List<WidgetGridCell>,
    style: WidgetThemeStyle,
) {
    Row(modifier = GlanceModifier.fillMaxSize()) {
        cells.forEachIndexed { index, cell ->
            WidgetGridCellContent(
                data = data,
                cell = cell,
                style = style,
                modifier =
                    GlanceModifier
                        .defaultWeight()
                        .fillMaxHeight()
                        .padding(end = if (index == 0) 2.dp else 0.dp),
            )
        }
    }
}

@Composable
private fun WidgetGridThreeCells(
    data: MomentWidgetData,
    cells: List<WidgetGridCell>,
    style: WidgetThemeStyle,
) {
    Column(modifier = GlanceModifier.fillMaxSize()) {
        Row(
            modifier =
                GlanceModifier
                    .fillMaxWidth()
                    .defaultWeight(),
        ) {
            WidgetGridCellContent(
                data = data,
                cell = cells[0],
                style = style,
                modifier =
                    GlanceModifier
                        .defaultWeight()
                        .fillMaxHeight()
                        .padding(end = 2.dp, bottom = 2.dp),
            )
            WidgetGridCellContent(
                data = data,
                cell = cells[1],
                style = style,
                modifier =
                    GlanceModifier
                        .defaultWeight()
                        .fillMaxHeight()
                        .padding(bottom = 2.dp),
            )
        }
        WidgetGridCellContent(
            data = data,
            cell = cells[2],
            style = style,
            modifier =
                GlanceModifier
                    .fillMaxWidth()
                    .defaultWeight(),
        )
    }
}

@Composable
private fun WidgetGridFourCells(
    data: MomentWidgetData,
    cells: List<WidgetGridCell>,
    style: WidgetThemeStyle,
) {
    Column(modifier = GlanceModifier.fillMaxSize()) {
        Row(
            modifier =
                GlanceModifier
                    .fillMaxWidth()
                    .defaultWeight(),
        ) {
            WidgetGridCellContent(
                data = data,
                cell = cells[0],
                style = style,
                modifier =
                    GlanceModifier
                        .defaultWeight()
                        .fillMaxHeight()
                        .padding(end = 2.dp, bottom = 2.dp),
            )
            WidgetGridCellContent(
                data = data,
                cell = cells[1],
                style = style,
                modifier =
                    GlanceModifier
                        .defaultWeight()
                        .fillMaxHeight()
                        .padding(bottom = 2.dp),
            )
        }
        Row(
            modifier =
                GlanceModifier
                    .fillMaxWidth()
                    .defaultWeight(),
        ) {
            WidgetGridCellContent(
                data = data,
                cell = cells[2],
                style = style,
                modifier =
                    GlanceModifier
                        .defaultWeight()
                        .fillMaxHeight()
                        .padding(end = 2.dp),
            )
            WidgetGridCellContent(
                data = data,
                cell = cells[3],
                style = style,
                modifier =
                    GlanceModifier
                        .defaultWeight()
                        .fillMaxHeight(),
            )
        }
    }
}

@Composable
private fun WidgetGridCellContent(
    data: MomentWidgetData,
    cell: WidgetGridCell,
    style: WidgetThemeStyle,
    modifier: GlanceModifier,
) {
    val context = LocalContext.current
    val entry = cell.entry
    val revealAction =
        if (cell.privacyMode == "full") {
            fullMomentRevealAction(context, entry.momentId, entry.imagePath)
        } else {
            null
        }
    val open = revealAction ?: openMomentAction(entry.momentId)

    Box(
        modifier = modifier,
        contentAlignment = Alignment.BottomStart,
    ) {
        Box(
            modifier =
                GlanceModifier
                    .fillMaxSize()
                    .clickable(open),
            contentAlignment = Alignment.BottomStart,
        ) {
        when (cell.privacyMode) {
            "private" ->
                Box(
                    modifier =
                        GlanceModifier
                            .fillMaxSize()
                            .background(ColorProvider(Color(0xFF121214))),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = "New moment",
                        style =
                            TextStyle(
                                color = ColorProvider(Color.White),
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Medium,
                            ),
                    )
                }
            else -> {
                if (cell.bitmap != null) {
                    Image(
                        provider = ImageProvider(cell.bitmap),
                        contentDescription = entry.momentId,
                        modifier = GlanceModifier.fillMaxSize(),
                        contentScale = ContentScale.Crop,
                    )
                } else {
                    Box(
                        modifier =
                            GlanceModifier
                                .fillMaxSize()
                                .background(ColorProvider(Color(0xFF1A1A1C))),
                    ) {}
                }
                if (cell.privacyMode == "blur") {
                    Box(
                        modifier =
                            GlanceModifier
                                .fillMaxSize()
                                .background(ColorProvider(Color(0x66000000))),
                    ) {}
                }
            }
        }
        if (cell.privacyMode == "blur" && (data.showSender || data.showTimestamp)) {
            Box(
                modifier = GlanceModifier.fillMaxSize(),
                contentAlignment = Alignment.BottomStart,
            ) {
                Box(
                    modifier =
                        GlanceModifier
                            .fillMaxWidth()
                            .height(36.dp)
                            .background(ColorProvider(Color(0xA6000000))),
                ) {}
                Column(modifier = GlanceModifier.padding(horizontal = 6.dp, vertical = 4.dp)) {
                    if (data.showSender) {
                        Text(
                            text = entry.senderName.ifBlank { "Friend" },
                            maxLines = 1,
                            style =
                                TextStyle(
                                    color = ColorProvider(Color.White),
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.Bold,
                                ),
                        )
                    }
                    if (data.showTimestamp) {
                        val time =
                            WidgetRelativeTime.format(entry.createdAtMillis)
                                .ifBlank { entry.relativeTime }
                        if (time.isNotBlank()) {
                            Text(
                                text = time,
                                style =
                                    TextStyle(
                                        color = ColorProvider(Color(0xCCFFFFFF)),
                                        fontSize = 9.sp,
                                    ),
                            )
                        }
                    }
                }
            }
        }
        }
    }
}

private fun fullMomentRevealAction(
    context: Context,
    momentId: String,
    imagePath: String?,
): Action? {
    if (momentId.isBlank() || imagePath.isNullOrBlank()) return null
    return actionStartActivity(
        WidgetRevealActivity.launchIntent(context, momentId, imagePath),
    )
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

private fun openMomentAction(momentId: String): Action =
    if (momentId.isNotBlank()) {
        actionRunCallback<WidgetOpenMomentAction>(
            actionParametersOf(WidgetOpenMomentAction.MomentIdKey to momentId),
        )
    } else {
        actionStartActivity(launchMainActivityIntent())
    }

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
