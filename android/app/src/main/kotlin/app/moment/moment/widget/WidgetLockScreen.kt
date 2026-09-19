package app.moment.moment.widget

import android.app.KeyguardManager
import android.content.Context

/** Device lock state for widget lock-screen privacy. */
object WidgetLockScreen {
    fun isDeviceLocked(context: Context): Boolean {
        val keyguard =
            context.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
        return keyguard?.isDeviceLocked == true
    }
}
