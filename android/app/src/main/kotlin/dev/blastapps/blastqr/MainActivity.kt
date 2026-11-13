package dev.blastapps.blastqr

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private var pendingPick: Pair<MethodChannel.Result, File>? = null
    private val copyExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "blastqr/camera")
            .setMethodCallHandler { call, result ->
                if (call.method == "supportedFrameRates") {
                    // The camera plugin asks for a fixed rate, so only fixed
                    // ranges are options.
                    result.success(
                        backCameraFpsRanges()
                            .filter { it[0] == it[1] }
                            .map { it[0] }
                            .distinct()
                            .sorted()
                    )
                } else {
                    result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "blastqr/debug")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "backCameraFpsRanges" -> result.success(backCameraFpsRanges())
                    "deviceModel" -> result.success("${Build.MANUFACTURER} ${Build.MODEL}")
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "blastqr/device")
            .setMethodCallHandler { call, result ->
                if (call.method == "availableMemory") {
                    result.success(availableMemory())
                } else {
                    result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "blastqr/files")
            .setMethodCallHandler { call, result ->
                if (call.method == "pickFiles") {
                    pickFiles(File(call.arguments as String), result)
                } else {
                    result.notImplemented()
                }
            }
    }

    // file_selector reads picked files into memory, which runs out on large
    // ones, so this copies them into the directory with a stream instead.
    private fun pickFiles(directory: File, result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("busy", "A pick is already in progress", null)
            return
        }
        pendingPick = result to directory
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("*/*")
            .putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
        startActivityForResult(intent, PICK_FILES_REQUEST)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_FILES_REQUEST) return
        val (result, directory) = pendingPick ?: return
        pendingPick = null
        val uris = buildList {
            val clip = data?.clipData
            if (clip != null) {
                for (i in 0 until clip.itemCount) add(clip.getItemAt(i).uri)
            } else {
                data?.data?.let(::add)
            }
        }
        if (resultCode != RESULT_OK || uris.isEmpty()) {
            result.success(emptyList<String>())
            return
        }
        copyExecutor.execute {
            val paths = uris.mapNotNull { copyToDirectory(it, directory) }
            runOnUiThread { result.success(paths) }
        }
    }

    // Keeps the name the provider shows, made unique within the directory.
    // Returns null if the file can't be read.
    private fun copyToDirectory(uri: Uri, directory: File): String? {
        val name = displayName(uri)
            ?.substringAfterLast('/')
            ?.trimStart('.')
            ?.ifBlank { null }
            ?: "file"
        var target = File(directory, name)
        var copy = 1
        while (target.exists()) {
            target = File(directory, "${name.substringBeforeLast('.')} (${copy++})" +
                if ('.' in name) ".${name.substringAfterLast('.')}" else "")
        }
        return try {
            val input = contentResolver.openInputStream(uri) ?: return null
            input.use { source ->
                target.outputStream().use { source.copyTo(it, 1 shl 16) }
            }
            target.path
        } catch (e: Exception) {
            Log.w("blastqr", "Couldn't copy picked file: ${e.message}")
            target.delete()
            null
        }
    }

    private fun displayName(uri: Uri): String? =
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else null
            }

    // Android closes background apps to make room, so about half of all
    // memory is usable even when much less is free right now.
    private fun availableMemory(): Long {
        val info = ActivityManager.MemoryInfo()
        (getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager).getMemoryInfo(info)
        return maxOf(info.availMem, info.totalMem / 2)
    }

    // The frame rate ranges apps may request from the first back camera,
    // which is the one the scanner opens.
    private fun backCameraFpsRanges(): List<List<Int>> {
        val manager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val id = manager.cameraIdList.firstOrNull {
            manager.getCameraCharacteristics(it)
                .get(CameraCharacteristics.LENS_FACING) == CameraCharacteristics.LENS_FACING_BACK
        } ?: return emptyList()
        val ranges = manager.getCameraCharacteristics(id)
            .get(CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES)
            ?: return emptyList()
        return ranges.map { listOf(it.lower, it.upper) }
    }

    companion object {
        private const val PICK_FILES_REQUEST = 7301
    }
}
