package app.moment.moment.widget

import android.graphics.Bitmap

/** One same-depth cell in the home-widget moment grid. */
data class WidgetGridCell(
    val entry: WidgetMomentEntry,
    val bitmap: Bitmap?,
    val privacyMode: String,
    val renderMode: WidgetRenderMode = WidgetRenderMode.FULL,
)
