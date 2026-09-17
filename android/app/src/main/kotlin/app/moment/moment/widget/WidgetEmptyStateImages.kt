package app.moment.moment.widget

import app.moment.moment.R
import java.util.Calendar

object WidgetEmptyStateImages {
    /**
     * Morning: 6 AM – 11:59 AM
     * Afternoon: 12 PM – 5:59 PM
     * Night: 6 PM – 5:59 AM
     */
    fun drawableRes(): Int {
        val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
        return when {
            hour < 6 || hour >= 18 -> R.drawable.widget_empty_moments_night
            hour < 12 -> R.drawable.widget_empty_moments_morning
            else -> R.drawable.widget_empty_moments_afternoon
        }
    }
}
