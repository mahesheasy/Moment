package app.moment.moment

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import app.moment.moment.widget.MomentWidgetDataStore
import app.moment.moment.widget.MomentWidgetReceiver
import app.moment.moment.widget.MomentWidgetUpdater
import app.moment.moment.widget.WidgetBitmap
import app.moment.moment.widget.WidgetMomentEntry
import app.moment.moment.widget.WidgetMomentQueue
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class WidgetBridgePlugin(
    private val context: Context,
) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "updateWidget" -> {
                @Suppress("UNCHECKED_CAST")
                val moments = call.argument<List<Map<String, Any?>>>("moments")
                if (!moments.isNullOrEmpty()) {
                    val entries =
                        moments.mapNotNull { map ->
                            val momentId = map["momentId"] as? String ?: return@mapNotNull null
                            val imageBytes = map["imageBytes"] as? ByteArray
                            val avatarBytes = map["avatarBytes"] as? ByteArray
                            WidgetMomentEntry(
                                momentId = momentId,
                                senderName = map["senderName"] as? String ?: "",
                                senderId = map["senderId"] as? String ?: "",
                                imagePath = saveWidgetImage(imageBytes, "moment_$momentId.jpg"),
                                avatarPath = saveWidgetImage(avatarBytes, "avatar_$momentId.jpg"),
                                caption = map["caption"] as? String ?: "",
                                createdAtMillis =
                                    (map["createdAtMillis"] as? Number)?.toLong()
                                        ?: System.currentTimeMillis(),
                                relativeTime = map["relativeTime"] as? String ?: "",
                            )
                        }
                    WidgetMomentQueue.saveQueue(context, entries, selectIndex = 0)
                    val first = entries.firstOrNull()
                    if (first != null) {
                        MomentWidgetDataStore.save(
                            context = context,
                            senderName = first.senderName,
                            momentId = first.momentId,
                            imagePath = first.imagePath,
                            caption = first.caption,
                            relativeTime = first.relativeTime,
                            createdAtMillis = first.createdAtMillis,
                            widgetMode = call.argument<String>("widgetMode"),
                            headerEmoji = call.argument<String>("headerEmoji"),
                            avatarPath = first.avatarPath,
                            senderId = first.senderId,
                        )
                    }
                    refreshWidget(result)
                    return
                }

                val senderName = call.argument<String>("senderName") ?: ""
                val momentId = call.argument<String>("momentId") ?: ""
                val caption = call.argument<String>("caption")
                val relativeTime = call.argument<String>("relativeTime")
                val createdAtMillis = createdAtFromCall(call)
                val widgetMode = call.argument<String>("widgetMode")
                val headerEmoji = call.argument<String>("headerEmoji")
                val imageBytes = call.argument<ByteArray>("imageBytes")
                val avatarBytes = call.argument<ByteArray>("avatarBytes")
                val imagePath = saveWidgetImage(imageBytes, "latest_moment.jpg")
                val avatarPath = saveWidgetImage(avatarBytes, "avatar.jpg")
                val senderId = call.argument<String>("senderId")

                MomentWidgetDataStore.save(
                    context = context,
                    senderName = senderName,
                    momentId = momentId,
                    imagePath = imagePath,
                    caption = caption,
                    relativeTime = relativeTime,
                    createdAtMillis = createdAtMillis,
                    widgetMode = widgetMode,
                    headerEmoji = headerEmoji,
                    avatarPath = avatarPath,
                    senderId = senderId,
                )
                refreshWidget(result)
            }

            "clearWidget" -> {
                MomentWidgetDataStore.clear(context)
                refreshWidget(result)
            }

            "syncPreferences" -> {
                val theme = call.argument<String>("theme") ?: "minimal"
                val accentColor = call.argument<String>("accentColor") ?: "#FF6B8A"
                val typography = call.argument<String>("typography") ?: "default"
                val widgetMode = call.argument<String>("widgetMode")
                val displaySize = call.argument<String>("displaySize")
                MomentWidgetDataStore.savePreferences(
                    context = context,
                    theme = theme,
                    accentColor = accentColor,
                    typography = typography,
                    widgetMode = widgetMode,
                    displaySize = displaySize,
                    privacyMode = call.argument<String>("privacyMode"),
                    showSender = call.argument<Boolean>("showSender"),
                    showTimestamp = call.argument<Boolean>("showTimestamp"),
                    showCaptions = call.argument<Boolean>("showCaptions"),
                    lockScreenPrivacy = call.argument<Boolean>("lockScreenPrivacy"),
                    paused = call.argument<Boolean>("paused"),
                    privacyPersonId = call.argument<String>("privacyPersonId"),
                )
                refreshWidget(result)
            }

            "getPreferences" -> {
                val data = MomentWidgetDataStore.load(context)
                val prefs =
                    context.getSharedPreferences(
                        MomentWidgetDataStore.PREFS,
                        Context.MODE_PRIVATE,
                    )
                result.success(
                    mapOf(
                        "hasCustomization" to (
                            prefs.getBoolean(
                                MomentWidgetDataStore.KEY_HAS_CUSTOMIZATION,
                                false,
                            ) || prefs.contains(MomentWidgetDataStore.KEY_THEME)
                        ),
                        "theme" to data.theme,
                        "accentColor" to data.accentColor,
                        "typography" to data.typography,
                        "widgetMode" to data.widgetMode,
                        "displaySize" to data.displaySize,
                        "privacyMode" to (prefs.getString(MomentWidgetDataStore.KEY_PRIVACY_MODE, "full") ?: "full"),
                        "showSender" to data.showSender,
                        "showTimestamp" to data.showTimestamp,
                        "showCaptions" to data.showCaptions,
                        "lockScreenPrivacy" to data.lockScreenPrivacy,
                        "paused" to data.paused,
                        "privacyPersonId" to (prefs.getString(MomentWidgetDataStore.KEY_PRIVACY_PERSON, "") ?: ""),
                    ),
                )
            }

            "isPinWidgetSupported" -> {
                val supported =
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        AppWidgetManager.getInstance(context).isRequestPinAppWidgetSupported
                    } else {
                        false
                    }
                result.success(supported)
            }

            "requestPinWidget" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val manager = AppWidgetManager.getInstance(context)
                    if (manager.isRequestPinAppWidgetSupported) {
                        val component =
                            ComponentName(context, MomentWidgetReceiver::class.java)
                        manager.requestPinAppWidget(component, null, null)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                } else {
                    result.success(false)
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun createdAtFromCall(call: MethodCall): Long {
        val raw = call.argument<Any>("createdAtMillis")
        val parsed =
            when (raw) {
                is Number -> raw.toLong()
                is String -> raw.toLongOrNull()
                else -> null
            }
        return parsed ?: System.currentTimeMillis()
    }

    private fun saveWidgetImage(imageBytes: ByteArray?, fileName: String): String? {
        if (imageBytes == null || imageBytes.isEmpty()) return null
        val dir = File(context.filesDir, "widget")
        if (!dir.exists()) dir.mkdirs()
        val file = File(dir, fileName)
        return WidgetBitmap.writeDownsampled(imageBytes, file)
    }

    private fun refreshWidget(result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.Main).launch {
            try {
                MomentWidgetUpdater.update(context)
                result.success(null)
            } catch (error: Exception) {
                result.error("widget_update_failed", error.message, null)
            }
        }
    }

    companion object {
        private const val CHANNEL = "app.moment/widget"

        fun register(flutterEngine: FlutterEngine, context: Context) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler(WidgetBridgePlugin(context.applicationContext))
        }
    }
}
