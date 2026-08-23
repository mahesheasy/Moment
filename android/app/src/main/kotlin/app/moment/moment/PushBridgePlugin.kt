package app.moment.moment

import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

/**
 * Exposes FCM registration to Dart.
 *
 * Message handling itself lives in [MomentFirebaseMessagingService] — Dart only
 * needs the token so it can be stored against the Supabase user.
 */
class PushBridgePlugin(
    private val context: Context,
    private val activity: Activity?,
) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getToken" -> {
                // Absent google-services.json there is no default FirebaseApp, so
                // treat push as unavailable rather than surfacing an error.
                val messaging = runCatching { FirebaseMessaging.getInstance() }.getOrNull()
                if (messaging == null) {
                    result.success(null)
                    return
                }
                messaging.token
                    .addOnSuccessListener { token ->
                        context.getSharedPreferences(
                            MomentFirebaseMessagingService.PUSH_PREFS,
                            Context.MODE_PRIVATE,
                        ).edit().remove(
                            MomentFirebaseMessagingService.KEY_PENDING_TOKEN,
                        ).apply()
                        result.success(token)
                    }
                    .addOnFailureListener { error ->
                        result.error("token_failed", error.message, null)
                    }
            }

            "deleteToken" -> {
                thread {
                    runCatching { FirebaseMessaging.getInstance().deleteToken() }
                    activity?.runOnUiThread { result.success(null) }
                        ?: result.success(null)
                }
            }

            "hasNotificationPermission" -> {
                result.success(hasPermission())
            }

            "requestNotificationPermission" -> {
                if (hasPermission()) {
                    result.success(true)
                    return
                }
                val host = activity
                if (host == null) {
                    result.success(false)
                    return
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    ActivityCompat.requestPermissions(
                        host,
                        arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                        PERMISSION_REQUEST_CODE,
                    )
                }
                // The dialog is async; Dart re-checks with hasNotificationPermission.
                result.success(false)
            }

            "syncNotificationPreferences" -> {
                @Suppress("UNCHECKED_CAST")
                val values = call.arguments as? Map<String, Boolean> ?: emptyMap()
                NotificationPreferencesStore.save(context, values)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun hasPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return context.checkSelfPermission(
            android.Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED
    }

    companion object {
        private const val CHANNEL = "app.moment/push"
        private const val PERMISSION_REQUEST_CODE = 4411

        fun register(flutterEngine: FlutterEngine, activity: Activity) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler(
                    PushBridgePlugin(activity.applicationContext, activity),
                )
        }
    }
}
