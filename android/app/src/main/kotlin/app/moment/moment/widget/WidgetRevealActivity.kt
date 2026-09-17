package app.moment.moment.widget

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.WindowManager
import android.widget.ImageView
import android.widget.ProgressBar
import app.moment.moment.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * Full-screen clear photo reveal when the home widget is tapped (Full privacy mode).
 * Marks the moment seen so the widget surface updates to the clear photo.
 */
class WidgetRevealActivity : Activity() {
    private val handler = Handler(Looper.getMainLooper())
    private var finished = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )

        val momentId = intent.getStringExtra(EXTRA_MOMENT_ID)
        val imagePath = intent.getStringExtra(EXTRA_IMAGE_PATH)
        if (momentId.isNullOrBlank() || imagePath.isNullOrBlank()) {
            finishImmediate()
            return
        }

        markSeenAndRefreshWidget(momentId)

        val bitmap = WidgetBitmap.decode(imagePath)
        if (bitmap == null) {
            openMomentAndFinish(momentId)
            return
        }

        setContentView(R.layout.activity_widget_reveal)
        val root = findViewById<android.view.View>(R.id.reveal_root)
        val image = findViewById<ImageView>(R.id.reveal_image)
        val ring = findViewById<ProgressBar>(R.id.reveal_countdown_ring)

        image.setImageBitmap(bitmap)
        val openMoment = { openMomentAndFinish(momentId) }
        root.setOnClickListener { openMoment() }
        image.setOnClickListener { openMoment() }

        val deadline = SystemClock.elapsedRealtime() + REVEAL_MAX_MS
        val tick =
            object : Runnable {
                override fun run() {
                    if (finished) return
                    val remaining = deadline - SystemClock.elapsedRealtime()
                    if (remaining <= 0) {
                        openMoment()
                        return
                    }
                    ring.progress =
                        (((REVEAL_MAX_MS - remaining) * 100) / REVEAL_MAX_MS).toInt()
                    handler.postDelayed(this, 50L)
                }
            }
        handler.post(tick)
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        val momentId = intent.getStringExtra(EXTRA_MOMENT_ID)
        if (!momentId.isNullOrBlank()) {
            openMomentAndFinish(momentId)
        } else {
            finishImmediate()
        }
    }

    override fun onStop() {
        super.onStop()
        finishImmediate()
    }

    private fun markSeenAndRefreshWidget(momentId: String) {
        WidgetMomentQueue.markSeenOnWidget(applicationContext, momentId)
        scope.launch {
            MomentWidgetUpdater.updatePreservingView(applicationContext)
        }
    }

    private fun openMomentAndFinish(momentId: String) {
        if (finished) return
        finished = true
        handler.removeCallbacksAndMessages(null)
        markSeenAndRefreshWidget(momentId)
        startActivity(launchDeepLink(momentId))
        if (!isFinishing) finish()
        overridePendingTransition(0, 0)
    }

    private fun finishImmediate() {
        if (finished) return
        finished = true
        handler.removeCallbacksAndMessages(null)
        if (!isFinishing) finish()
        overridePendingTransition(0, 0)
    }

    companion object {
        const val EXTRA_MOMENT_ID = "moment_id"
        const val EXTRA_IMAGE_PATH = "image_path"
        private const val REVEAL_MAX_MS = 3_000L
        private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

        fun launchIntent(
            context: Context,
            momentId: String,
            imagePath: String,
        ): Intent =
            Intent(context, WidgetRevealActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION)
                putExtra(EXTRA_MOMENT_ID, momentId)
                putExtra(EXTRA_IMAGE_PATH, imagePath)
            }

        private fun launchDeepLink(momentId: String): Intent =
            Intent(Intent.ACTION_VIEW, Uri.parse("moment://moment/$momentId")).apply {
                setClassName("app.moment.moment", "app.moment.moment.MainActivity")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
    }
}
