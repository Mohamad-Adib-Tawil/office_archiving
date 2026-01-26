package com.werewolf.office_archiving

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.werewolf.office_archiving/open_file"
    private var pendingUri: Uri? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
        maybeDispatchPending()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        maybeDispatchPending()
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_VIEW) {
            pendingUri = intent.data
        }
    }

    private fun maybeDispatchPending() {
        val uri = pendingUri ?: return
        val channel = methodChannel ?: return

        // Copy the URI to a readable cache file and send the absolute path to Flutter
        try {
            val path = copyUriToCache(uri)
            channel.invokeMethod("openFile", path)
            pendingUri = null
        } catch (e: Exception) {
            // Optionally report error to Flutter side in the future
        }
    }

    private fun copyUriToCache(uri: Uri): String {
        val resolver = applicationContext.contentResolver
        val name = getDisplayName(uri) ?: ("opened_" + System.currentTimeMillis())
        val dir = File(cacheDir, "received")
        if (!dir.exists()) dir.mkdirs()
        val outFile = File(dir, name)

        resolver.openInputStream(uri).use { input ->
            FileOutputStream(outFile).use { output ->
                if (input != null) {
                    input.copyTo(output)
                }
            }
        }
        return outFile.absolutePath
    }

    private fun getDisplayName(uri: Uri): String? {
        val resolver = applicationContext.contentResolver
        val cursor = resolver.query(uri, null, null, null, null) ?: return uri.lastPathSegment
        cursor.use {
            val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (nameIndex != -1 && cursor.moveToFirst()) {
                return cursor.getString(nameIndex)
            }
        }
        return uri.lastPathSegment
    }
}
