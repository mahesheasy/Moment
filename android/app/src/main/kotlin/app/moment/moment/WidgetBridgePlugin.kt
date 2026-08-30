package app.moment.moment

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import app.moment.moment.widget.MomentWidgetDataStore
import app.moment.moment.widget.MomentWidgetReceiver
import app.moment.moment.widget.MomentWidgetUpdater
import app.moment.moment.widget.WidgetBitmap
import app.moment.moment.widget.WidgetSyncCredentialsStore
import app.moment.moment.widget.WidgetMediaDownloader
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
    private val scope = CoroutineScope(Dispatchers.Main.immediate)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "saveWidgetSyncSession" -> {
                val supabaseUrl = call.argument<String>("supabaseUrl").orEmpty()
                val anonKey = call.argument<String>("supabaseAnonKey").orEmpty()
                val userId = call.argument<String>("userId").orEmpty()
                val accessToken = call.argument<String>("accessToken").orEmpty()
                val refreshToken = call.argument<String>("refreshToken")
                if (supabaseUrl.isNotBlank() && anonKey.isNotBlank() &&
                    userId.isNotBlank() && accessToken.isNotBlank()
                ) {
                    WidgetSyncCredentialsStore.save(
                        context,
                        supabaseUrl,
                        anonKey,
                        userId,
                        accessToken,
                        refreshToken,
                    )
                }
                result.success(null)
            }

            "clearWidgetSyncSession" -> {
                WidgetSyncCredentialsStore.clear(context)
                result.success(null)
            }

            "pushIncomingMoment" -> {
                val momentId = call.argument<String>("momentId").orEmpty()
                if (momentId.isBlank()) {
                    result.success(null)
                    return
                }
                val imageUrl = call.argument<String>("imageUrl")
                val avatarUrl = call.argument<String>("avatarUrl")
                val entry =
                    WidgetMomentEntry(
                        momentId = momentId,
                        senderName = call.argument<String>("senderName") ?: "",
                        senderId = call.argument<String>("senderId") ?: "",
                        imagePath = null,
                        avatarPath = null,
                        caption = call.argument<String>("caption") ?: "",
                        createdAtMillis = createdAtFromCall(call),
                        relativeTime = call.argument<String>("relativeTime") ?: "",
                        imageUrl = imageUrl?.takeIf { it.isNotBlank() },
                        avatarUrl = avatarUrl?.takeIf { it.isNotBlank() },
                    )
                WidgetMomentQueue.upsertMoment(context, entry, promoteNew = true)
                WidgetMediaDownloader.enqueue(context, momentId, imageUrl, avatarUrl)
                scope.launch {
                    MomentWidgetUpdater.updateIncomingMoment(context, momentId)
                    result.success(null)
                }
            }

            "updateWidget" -> {
                @Suppress("UNCHECKED_CAST")
                val moments = call.argument<List<Map<String, Any?>>>("moments")
                if (!moments.isNullOrEmpty()) {
                    val showLatest = call.argument<Boolean>("showLatest") ?: true
                    val syncGeneration =
                        (call.argument<Number>("syncGeneration") ?: 0L).toLong()
                    val entries =
                        moments.mapNotNull { map ->
                            val momentId = map["momentId"] as? String ?: return@mapNotNull null
                            val imageBytes = map["imageBytes"] as? ByteArray
                            val avatarBytes = map["avatarBytes"] as? ByteArray
                            val imageUrl = map["imageUrl"] as? String
                            val avatarUrl = map["avatarUrl"] as? String
                            WidgetMomentEntry(
                                momentId = momentId,
                                senderName = map["senderName"] as? String ?: "",
                                senderId = map["senderId"] as? String ?: "",
                                imagePath = saveWidgetImage(imageBytes, "moment_$momentId.jpg"),
                                avatarPath = saveWidgetImage(avatarBytes, "avatar_$momentId.jpg"),
                                caption = map["caption"] as? String ?: "",
                                createdAtMillis =
                                    (map["createdAtMillis"] as? Number)?.toLong() ?: 0L,
                                relativeTime = map["relativeTime"] as? String ?: "",
                                imageUrl = imageUrl?.takeIf { it.isNotBlank() },
                                avatarUrl = avatarUrl?.takeIf { it.isNotBlank() },
                            )
                        }
                    if (entries.isNotEmpty()) {
                        WidgetMomentQueue.mergeQueue(
                            context,
                            entries,
                            showLatest = showLatest,
                            syncGeneration = syncGeneration,
                        )
                        entries.forEach { entry ->
                            WidgetMediaDownloader.enqueue(
                                context,
                                entry.momentId,
                                entry.imageUrl,
                                entry.avatarUrl,
                            )
                        }
                        refreshWidget(result, showLatest = showLatest)
                        return
                    }
                }

                val senderName = call.argument<String>("senderName") ?: ""
                val momentId = call.argument<String>("momentId") ?: ""
                val caption = call.argument<String>("caption")
                val relativeTime = call.argument<String>("relativeTime")
                val createdAtMillis = createdAtFromCall(call)
                val imageBytes = call.argument<ByteArray>("imageBytes")
                val avatarBytes = call.argument<ByteArray>("avatarBytes")
                val imageUrl = call.argument<String>("imageUrl")
                val avatarUrl = call.argument<String>("avatarUrl")
                val imagePath = saveWidgetImage(imageBytes, "moment_$momentId.jpg")
                val avatarPath = saveWidgetImage(avatarBytes, "avatar_$momentId.jpg")
                val senderId = call.argument<String>("senderId")

                val entry =
                    WidgetMomentEntry(
                        momentId = momentId,
                        senderName = senderName,
                        senderId = senderId.orEmpty(),
                        imagePath = imagePath,
                        avatarPath = avatarPath,
                        caption = caption.orEmpty(),
                        createdAtMillis = createdAtMillis,
                        relativeTime = relativeTime.orEmpty(),
                        imageUrl = imageUrl?.takeIf { it.isNotBlank() },
                        avatarUrl = avatarUrl?.takeIf { it.isNotBlank() },
                    )
                WidgetMomentQueue.upsertMoment(context, entry, promoteNew = true)
                WidgetMediaDownloader.enqueue(context, momentId, imageUrl, avatarUrl)
                refreshWidget(result, showLatest = true)
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
                    showStreak = call.argument<Boolean>("showStreak"),
                    streakCount = call.argument<Int>("streakCount"),
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
                        "showStreak" to data.showStreak,
                        "streakCount" to data.streakCount,
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
        return parsed ?: 0L
    }

    private fun saveWidgetImage(imageBytes: ByteArray?, fileName: String): String? {
        if (imageBytes == null || imageBytes.isEmpty()) return null
        val dir = File(context.filesDir, "widget")
        if (!dir.exists()) dir.mkdirs()
        val file = File(dir, fileName)
        return WidgetBitmap.writeDownsampled(imageBytes, file)
    }

    private fun refreshWidget(
        result: MethodChannel.Result,
        showLatest: Boolean = false,
    ) {
        scope.launch {
            runCatching {
                val active = WidgetMomentQueue.activeEntry(context)
                if (showLatest && active != null) {
                    MomentWidgetUpdater.updateIncomingMoment(context, active.momentId)
                } else {
                    MomentWidgetUpdater.updatePreservingView(context)
                }
            }
            result.success(null)
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
