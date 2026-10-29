package cat.cukha.blastqr

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
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
}
