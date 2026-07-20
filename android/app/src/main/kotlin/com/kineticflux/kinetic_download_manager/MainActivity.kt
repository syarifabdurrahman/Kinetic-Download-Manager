package com.kineticflux.kinetic_download_manager

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.webkit.CookieManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "kinetic_flux/share"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kinetic_flux/cookies").setMethodCallHandler { call, result ->
            if (call.method == "getCookies") {
                val url = call.argument<String>("url")
                if (url != null) {
                    val cookies = CookieManager.getInstance().getCookie(url)
                    result.success(cookies)
                } else {
                    result.error("INVALID_ARGS", "url required", null)
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kinetic_flux/file_explorer").setMethodCallHandler { call, result ->
            if (call.method == "showInFolder") {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("INVALID_ARGS", "path required", null)
                    return@setMethodCallHandler
                }
                try {
                    // Try Samsung My Files
                    val samsungIntent = Intent(Intent.ACTION_VIEW).apply {
                        component = ComponentName("com.sec.android.app.myfiles", "com.sec.android.app.myfiles.MainActivity")
                        data = Uri.parse("storageRoot:/storage/emulated/0/Download/KFDM")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    try {
                        startActivity(samsungIntent)
                        result.success(true)
                        return@setMethodCallHandler
                    } catch (_: Exception) {}
                    // Fallback: SAF DocumentsContract
                    val relative = path.removePrefix("/storage/emulated/0/").removePrefix("/")
                    if (relative.isNotEmpty()) {
                        val docId = "primary:" + relative
                        val uri = DocumentsContract.buildDocumentUri("com.android.externalstorage.documents", docId)
                        val safIntent = Intent(Intent.ACTION_VIEW).apply {
                            data = uri
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(safIntent)
                        result.success(true)
                        return@setMethodCallHandler
                    }
                    result.error("NO_APP", "No file explorer found", null)
                } catch (e: Exception) {
                    result.error("OPEN_FAILED", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "getPendingUrl") {
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val url: String? = when (intent.action) {
            Intent.ACTION_SEND -> {
                if (intent.type == "text/plain") {
                    intent.getStringExtra(Intent.EXTRA_TEXT)?.let { text ->
                        text.lines().firstOrNull { line ->
                            line.startsWith("http://") || line.startsWith("https://")
                        } ?: text
                    }
                } else null
            }
            Intent.ACTION_VIEW -> intent.data?.toString()
            else -> null
        }

        if (url != null) {
            methodChannel?.invokeMethod("onUrl", url)
        }
    }
}
