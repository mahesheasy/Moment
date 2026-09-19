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
import app.moment.moment.widget.WidgetOemReliability
import app.moment.moment.widget.WidgetPrivacyOverridesStore
import app.moment.moment.widget.WidgetPrivacyResolver
import app.moment.moment.widget.WidgetPrivateImageGuard
import app.moment.moment.widget.WidgetRenderLatency
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
                        isUnread = call.argument<Boolean>("isUnread") ?: true,
                    )
                WidgetMomentQueue.setDisplayMoment(context, entry)
                WidgetRenderLatency.begin(momentId, "realtime", entry.createdAtMillis)
                enqueueMomentMedia(
                    senderId = entry.senderId,
                    momentId = momentId,
                    imageUrl = imageUrl,
                    avatarUrl = avatarUrl,
                )
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
                    val replaceQueue = call.argument<Boolean>("replaceQueue") ?: false
                    val syncGeneration =
                        (call.argument<Number>("syncGeneration") ?: 0L).toLong()
                    val entries =
                        moments.mapNotNull { map ->
                            val momentId = map["momentId"] as? String ?: return@mapNotNull null
                            val imageBytes = map["imageBytes"] as? ByteArray
                            val avatarBytes = map["avatarBytes"] as? ByteArray
                            val imageUrl = map["imageUrl"] as? String
                            val avatarUrl = map["avatarUrl"] as? String
                            val senderId = map["senderId"] as? String ?: ""
                            val privacyMode =
                                WidgetPrivacyResolver.resolvePrivacyForSender(
                                    context,
                                    senderId,
                                )
                            var imagePath =
                                saveWidgetImage(imageBytes, "moment_$momentId.jpg")
                            if (!WidgetPrivateImageGuard.shouldCacheMomentImage(privacyMode)) {
                                WidgetPrivateImageGuard.purgePath(imagePath)
                                imagePath = null
                            }
                            WidgetMomentEntry(
                                momentId = momentId,
                                senderName = map["senderName"] as? String ?: "",
                                senderId = senderId,
                                imagePath = imagePath,
                                avatarPath = saveWidgetImage(avatarBytes, "avatar_$momentId.jpg"),
                                caption = map["caption"] as? String ?: "",
                                createdAtMillis =
                                    (map["createdAtMillis"] as? Number)?.toLong() ?: 0L,
                                relativeTime = map["relativeTime"] as? String ?: "",
                                imageUrl = imageUrl?.takeIf { it.isNotBlank() },
                                avatarUrl = avatarUrl?.takeIf { it.isNotBlank() },
                                isUnread = map["isUnread"] as? Boolean ?: true,
                            )
                        }
                    if (entries.isNotEmpty()) {
                        if (replaceQueue && entries.size == 1) {
                            WidgetMomentQueue.setDisplayMoment(context, entries.first())
                        } else {
                            WidgetMomentQueue.mergeQueue(
                                context,
                                entries,
                                showLatest = showLatest,
                                syncGeneration = syncGeneration,
                            )
                        }
                        entries.forEach { entry ->
                            enqueueMomentMedia(
                                senderId = entry.senderId,
                                momentId = entry.momentId,
                                imageUrl = entry.imageUrl,
                                avatarUrl = entry.avatarUrl,
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
                var imagePath = saveWidgetImage(imageBytes, "moment_$momentId.jpg")
                val avatarPath = saveWidgetImage(avatarBytes, "avatar_$momentId.jpg")
                val senderId = call.argument<String>("senderId").orEmpty()
                val privacyMode =
                    WidgetPrivacyResolver.resolvePrivacyForSender(context, senderId)
                if (!WidgetPrivateImageGuard.shouldCacheMomentImage(privacyMode)) {
                    WidgetPrivateImageGuard.purgePath(imagePath)
                    imagePath = null
                }

                val entry =
                    WidgetMomentEntry(
                        momentId = momentId,
                        senderName = senderName,
                        senderId = senderId,
                        imagePath = imagePath,
                        avatarPath = avatarPath,
                        caption = caption.orEmpty(),
                        createdAtMillis = createdAtMillis,
                        relativeTime = relativeTime.orEmpty(),
                        imageUrl = imageUrl?.takeIf { it.isNotBlank() },
                        avatarUrl = avatarUrl?.takeIf { it.isNotBlank() },
                    )
                WidgetMomentQueue.upsertMoment(context, entry, promoteNew = true)
                enqueueMomentMedia(
                    senderId = senderId,
                    momentId = momentId,
                    imageUrl = imageUrl,
                    avatarUrl = avatarUrl,
                )
                refreshWidget(result, showLatest = true)
            }

            "clearWidget" -> {
                MomentWidgetDataStore.clear(context)
                refreshWidget(result)
            }

            "markMomentViewed" -> {
                val momentId = call.argument<String>("momentId").orEmpty()
                if (momentId.isNotBlank()) {
                    WidgetMomentQueue.markViewed(context, momentId)
                    refreshWidget(result, showLatest = false)
                } else {
                    result.success(null)
                }
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
                    privacyOverridesJson = call.argument<String>("privacyOverridesJson"),
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
                        "privacyOverridesJson" to (
                            prefs.getString(WidgetPrivacyOverridesStore.KEY_PRIVACY_OVERRIDES, "{}")
                                ?: "{}"
                        ),
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

            "getBackgroundReliability" -> {
                result.success(WidgetOemReliability.statusMap(context))
            }

            "requestBatteryOptimizationExemption" -> {
                result.success(
                    WidgetOemReliability.requestIgnoreBatteryOptimizations(context),
                )
            }

            "openAutostartSettings" -> {
                result.success(WidgetOemReliability.openAutostartSettings(context))
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

    private fun enqueueMomentMedia(
        senderId: String,
        momentId: String,
        imageUrl: String?,
        avatarUrl: String?,
    ) {
        val privacyMode = WidgetPrivacyResolver.resolvePrivacyForSender(context, senderId)
        if (!WidgetPrivateImageGuard.shouldCacheMomentImage(privacyMode)) {
            WidgetMomentQueue.findEntry(context, momentId)?.let { entry ->
                WidgetPrivateImageGuard.purgeMomentImage(context, entry)
            }
            return
        }
        WidgetMediaDownloader.enqueue(context, momentId, imageUrl, avatarUrl)
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
                    WidgetRenderLatency.begin(
                        active.momentId,
                        "flutter-sync",
                        active.createdAtMillis,
                    )
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
