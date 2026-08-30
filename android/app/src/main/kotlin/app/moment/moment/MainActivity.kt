package app.moment.moment

import app.moment.moment.widget.MomentWidgetUpdater
import app.moment.moment.widget.WidgetMediaPrivacyPreview
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private val widgetScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        WidgetBridgePlugin.register(flutterEngine, this)
        PushBridgePlugin.register(flutterEngine, this)
    }

    override fun onPause() {
        WidgetMediaPrivacyPreview.protectImmediately(this)
        widgetScope.launch {
            MomentWidgetUpdater.updatePreservingView(this@MainActivity)
        }
        super.onPause()
    }
}
