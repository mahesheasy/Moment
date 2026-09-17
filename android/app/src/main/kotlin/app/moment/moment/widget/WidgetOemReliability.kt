package app.moment.moment.widget

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log

/**
 * OEMs popular in India (Xiaomi, Oppo, Vivo, OnePlus) aggressively kill background
 * work unless the user disables battery restrictions and enables autostart.
 */
object WidgetOemReliability {
    private const val TAG = "WidgetOemReliability"

    enum class OemBrand {
        XIAOMI,
        OPPO,
        VIVO,
        ONEPLUS,
        REALME,
        SAMSUNG,
        OTHER,
    }

    fun detectOem(): OemBrand {
        val manufacturer = Build.MANUFACTURER.orEmpty().lowercase()
        val brand = Build.BRAND.orEmpty().lowercase()
        return when {
            manufacturer.contains("xiaomi") || brand.contains("redmi") ||
                brand.contains("poco") || brand.contains("mi") -> OemBrand.XIAOMI
            manufacturer.contains("oppo") || brand.contains("oppo") -> OemBrand.OPPO
            manufacturer.contains("vivo") || brand.contains("iqoo") -> OemBrand.VIVO
            manufacturer.contains("oneplus") -> OemBrand.ONEPLUS
            manufacturer.contains("realme") -> OemBrand.REALME
            manufacturer.contains("samsung") -> OemBrand.SAMSUNG
            else -> OemBrand.OTHER
        }
    }

    fun isIgnoringBatteryOptimizations(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val pm = context.getSystemService(PowerManager::class.java) ?: return true
        return pm.isIgnoringBatteryOptimizations(context.packageName)
    }

    /** Opens the system dialog to exempt this app from battery optimization. */
    fun requestIgnoreBatteryOptimizations(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        if (isIgnoringBatteryOptimizations(context)) return true
        return runCatching {
            val intent =
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:${context.packageName}")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            context.startActivity(intent)
            true
        }.getOrElse {
            Log.w(TAG, "Battery exemption intent failed", it)
            openBatteryOptimizationSettings(context)
        }
    }

    fun openBatteryOptimizationSettings(context: Context): Boolean =
        runCatching {
            val intent =
                Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            context.startActivity(intent)
            true
        }.getOrElse {
            Log.w(TAG, "Battery settings intent failed", it)
            openAppDetails(context)
        }

    /** Best-effort OEM autostart screen; falls back to app details. */
    fun openAutostartSettings(context: Context): Boolean {
        val pkg = context.packageName
        val intents =
            when (detectOem()) {
                OemBrand.XIAOMI ->
                    listOf(
                        component(
                            "com.miui.securitycenter",
                            "com.miui.permcenter.autostart.AutoStartManagementActivity",
                        ),
                        component(
                            "com.miui.securitycenter",
                            "com.miui.permcenter.permissions.PermissionsEditorActivity",
                            pkg,
                        ),
                    )
                OemBrand.OPPO, OemBrand.REALME ->
                    listOf(
                        component(
                            "com.coloros.safecenter",
                            "com.coloros.safecenter.permission.startup.StartupAppListActivity",
                        ),
                        component(
                            "com.oppo.safe",
                            "com.oppo.safe.permission.startup.StartupAppListActivity",
                        ),
                    )
                OemBrand.VIVO ->
                    listOf(
                        component(
                            "com.vivo.permissionmanager",
                            "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
                        ),
                        component(
                            "com.iqoo.secure",
                            "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity",
                            pkg,
                        ),
                    )
                OemBrand.ONEPLUS ->
                    listOf(
                        component(
                            "com.oneplus.security",
                            "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity",
                        ),
                    )
                else -> emptyList()
            }

        for (intent in intents) {
            if (tryStart(context, intent)) return true
        }
        return openAppDetails(context)
    }

    fun openAppDetails(context: Context): Boolean =
        runCatching {
            val intent =
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.fromParts("package", context.packageName, null)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            context.startActivity(intent)
            true
        }.getOrElse {
            Log.w(TAG, "App details intent failed", it)
            false
        }

    fun autostartGuidance(oem: OemBrand): String =
        when (oem) {
            OemBrand.XIAOMI ->
                "Settings → Apps → Manage apps → Moment → Autostart ON, " +
                    "and set Battery saver to No restrictions."
            OemBrand.OPPO, OemBrand.REALME ->
                "Settings → Battery → More battery settings → Optimize battery use → " +
                    "Moment → Don't optimize. Also enable Autostart for Moment."
            OemBrand.VIVO ->
                "Settings → Battery → Background power consumption management → " +
                    "Moment → Allow background activity. Enable Autostart for Moment."
            OemBrand.ONEPLUS ->
                "Settings → Battery → Battery optimization → Moment → Don't optimize. " +
                    "Enable Allow background activity / Autostart if shown."
            OemBrand.SAMSUNG ->
                "Settings → Battery → Background usage limits → remove Moment from " +
                    "Sleeping/Deep sleeping apps. Set Battery → Unrestricted."
            OemBrand.OTHER ->
                "Settings → Apps → Moment → Battery → Unrestricted. " +
                    "Disable battery optimization for reliable widget updates."
        }

    fun statusMap(context: Context): Map<String, Any> {
        val oem = detectOem()
        return mapOf(
            "oem" to oem.name.lowercase(),
            "batteryUnrestricted" to isIgnoringBatteryOptimizations(context),
            "needsAttention" to needsAttention(context),
            "autostartGuidance" to autostartGuidance(oem),
        )
    }

    fun needsAttention(context: Context): Boolean {
        if (!isIgnoringBatteryOptimizations(context)) return true
        return detectOem() in
            setOf(
                OemBrand.XIAOMI,
                OemBrand.OPPO,
                OemBrand.VIVO,
                OemBrand.ONEPLUS,
                OemBrand.REALME,
            )
    }

    private fun component(
        pkg: String,
        cls: String,
        extraPackage: String? = null,
    ): Intent =
        Intent().apply {
            component = ComponentName(pkg, cls)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (extraPackage != null) {
                putExtra("package_name", extraPackage)
                putExtra("packageName", extraPackage)
            }
        }

    private fun tryStart(context: Context, intent: Intent): Boolean =
        runCatching {
            context.packageManager.getActivityInfo(intent.component!!, 0)
            context.startActivity(intent)
            true
        }.getOrElse {
            Log.d(TAG, "OEM intent unavailable: ${intent.component}", it)
            false
        }
}
