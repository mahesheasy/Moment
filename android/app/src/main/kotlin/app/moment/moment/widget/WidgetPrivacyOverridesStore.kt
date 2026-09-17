package app.moment.moment.widget

import android.content.Context
import org.json.JSONObject

object WidgetPrivacyOverridesStore {
    const val KEY_PRIVACY_OVERRIDES = "privacy_overrides_json"

    private val MODES = setOf("full", "blur", "private")

    fun load(context: Context): Map<String, String> {
        val raw =
            context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
                .getString(KEY_PRIVACY_OVERRIDES, null)
                ?: return emptyMap()
        return runCatching {
            val json = JSONObject(raw)
            buildMap {
                json.keys().forEach { key ->
                    val mode = json.optString(key)
                    if (mode in MODES) put(key, mode)
                }
            }
        }.getOrDefault(emptyMap())
    }

    fun save(context: Context, overrides: Map<String, String>) {
        val json = JSONObject()
        overrides.forEach { (senderId, mode) ->
            if (senderId.isNotBlank() && mode in MODES) {
                json.put(senderId, mode)
            }
        }
        context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_PRIVACY_OVERRIDES, json.toString())
            .commit()
    }
}
