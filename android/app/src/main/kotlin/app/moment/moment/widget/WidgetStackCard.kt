package app.moment.moment.widget

import android.graphics.Bitmap

/** One layer in the home-widget card stack (front = depth 0). */
data class WidgetStackCard(
    val entry: WidgetMomentEntry,
    val bitmap: Bitmap?,
    val depth: Int,
)
