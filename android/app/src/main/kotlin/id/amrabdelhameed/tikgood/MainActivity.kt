package id.amrabdelhameed.tikgood

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityManager
import com.thesparks.android_pip.PipCallbackHelperActivityWrapper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : PipCallbackHelperActivityWrapper() {

    private val channel = "id.amrabdelhameed.tikgood/accessibility"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    "isServiceEnabled" -> {
                        val am = getSystemService(ACCESSIBILITY_SERVICE) as AccessibilityManager
                        val enabled = am.getEnabledAccessibilityServiceList(
                            AccessibilityServiceInfo.FEEDBACK_ALL_MASK
                        ).any {
                            it.resolveInfo.serviceInfo.packageName == "id.amrabdelhameed.tikgood" &&
                            it.resolveInfo.serviceInfo.name == "id.amrabdelhameed.tikgood.TikTokInterceptService"
                        }
                        result.success(enabled)
                    }
                    "requestOverlayPermission" -> {
                        if (!Settings.canDrawOverlays(this)) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:id.amrabdelhameed.tikgood")
                            )
                            startActivity(intent)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}