package app.moment.moment.widget

import android.os.SystemClock
import android.util.Log
import java.util.concurrent.ConcurrentHashMap

/**
 * Measures send → home-widget render latency.
 *
 * Log tag: MomentSync
 * Filter: adb logcat -s MomentSync | findstr LATENCY
 *
 * - metadata_ms: device pipeline (signal received → first Glance redraw)
 * - photo_ms: device pipeline (signal received → photo on widget)
 * - since_send_ms: wall clock from server [created_at] → metadata render
 * - total_since_send_ms: wall clock from server [created_at] → photo render
 */
internal object WidgetRenderLatency {
    private const val TAG = "MomentSync"

    private data class Track(
        val momentId: String,
        val source: String,
        val createdAtMillis: Long,
        val pipelineStartElapsed: Long,
    )

    private val tracks = ConcurrentHashMap<String, Track>()

    /** Call when FCM / realtime / sync delivers a moment to native code. */
    fun begin(momentId: String, source: String, createdAtMillis: Long) {
        if (momentId.isBlank()) return
        val nowElapsed = SystemClock.elapsedRealtime()
        tracks.putIfAbsent(
            momentId,
            Track(
                momentId = momentId,
                source = source,
                createdAtMillis = createdAtMillis.coerceAtLeast(0L),
                pipelineStartElapsed = nowElapsed,
            ),
        )
    }

    /** First Glance redraw with sender name / blur (metadata visible). */
    fun onMetadataRendered(momentId: String) {
        val track = tracks[momentId] ?: return
        val pipelineMs = SystemClock.elapsedRealtime() - track.pipelineStartElapsed
        val sinceSendMs = sinceSendMs(track)
        Log.d(
            TAG,
            "LATENCY momentId=$momentId source=${track.source} " +
                "metadata_ms=$pipelineMs since_send_ms=$sinceSendMs",
        )
    }

    /** Glance redraw after moment photo is on disk (full render). */
    fun onPhotoRendered(momentId: String) {
        val track = tracks.remove(momentId) ?: return
        val pipelineMs = SystemClock.elapsedRealtime() - track.pipelineStartElapsed
        val sinceSendMs = sinceSendMs(track)
        Log.d(
            TAG,
            "LATENCY momentId=$momentId source=${track.source} " +
                "photo_ms=$pipelineMs total_since_send_ms=$sinceSendMs",
        )
    }

    fun abandon(momentId: String) {
        tracks.remove(momentId)
    }

    private fun sinceSendMs(track: Track): Long {
        if (track.createdAtMillis <= 0L) return -1L
        return (System.currentTimeMillis() - track.createdAtMillis).coerceAtLeast(0L)
    }
}
