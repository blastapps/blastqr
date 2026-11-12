package dev.blastapps.blastqr_video

import android.content.Context
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.audio.ChannelMixingAudioProcessor
import androidx.media3.common.audio.ChannelMixingMatrix
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.FrameDropEffect
import androidx.media3.effect.Presentation
import androidx.media3.transformer.AudioEncoderSettings
import androidx.media3.transformer.Composition
import androidx.media3.transformer.DefaultEncoderFactory
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.EditedMediaItemSequence
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.InAppMp4Muxer
import androidx.media3.transformer.ProgressHolder
import androidx.media3.transformer.Transformer
import androidx.media3.transformer.VideoEncoderSettings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Re-encodes videos to H.264 and AAC in an MP4 with Media3 Transformer, which
 * applies the rotation, scales, drops frames above the frame rate and tone
 * maps HDR to SDR.
 */
@OptIn(UnstableApi::class)
class BlastqrVideoPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private class Job(
        val transformer: Transformer,
        val output: File,
        val result: MethodChannel.Result,
    )

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val handler = Handler(Looper.getMainLooper())
    private val probeExecutor = Executors.newSingleThreadExecutor()
    private val jobs = mutableMapOf<Int, Job>()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "blastqr_video")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        for (id in jobs.keys.toList()) cancel(id)
        probeExecutor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "probe" -> probe(call.arguments as String, result)
            "compress" -> compress(call, result)
            "cancel" -> {
                cancel(call.arguments as Int)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun probe(path: String, result: MethodChannel.Result) {
        probeExecutor.execute {
            val retriever = MediaMetadataRetriever()
            try {
                retriever.setDataSource(path)
                fun read(key: Int) = retriever.extractMetadata(key)
                val width = read(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull()
                val height = read(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull()
                if (width == null || height == null) {
                    handler.post { result.error("failed", "No video track", null) }
                    return@execute
                }
                val rotation =
                    read(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
                val rotated = rotation % 180 != 0
                val info = mapOf(
                    "durationMs" to
                        (read(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toDoubleOrNull()
                            ?: 0.0),
                    "width" to if (rotated) height else width,
                    "height" to if (rotated) width else height,
                    "hasAudio" to (read(MediaMetadataRetriever.METADATA_KEY_HAS_AUDIO) == "yes"),
                )
                handler.post { result.success(info) }
            } catch (e: Exception) {
                handler.post { result.error("failed", e.message, null) }
            } finally {
                runCatching { retriever.release() }
            }
        }
    }

    private fun compress(call: MethodCall, result: MethodChannel.Result) {
        val id = call.argument<Int>("id")!!
        val input = File(call.argument<String>("input")!!)
        val output = File(call.argument<String>("output")!!)
        val videoBitrate = call.argument<Int>("videoBitrate")!!
        val audioBitrate = call.argument<Int>("audioBitrate")!!
        val shortSide = call.argument<Int>("shortSide")!!
        val frameRate = call.argument<Int>("frameRate")!!
        val audioChannels = call.argument<Int>("audioChannels") ?: 2
        output.delete()

        val encoderFactory = DefaultEncoderFactory.Builder(context)
            .setRequestedVideoEncoderSettings(
                VideoEncoderSettings.Builder().setBitrate(videoBitrate).build()
            )
            .setRequestedAudioEncoderSettings(
                AudioEncoderSettings.Builder().setBitrate(audioBitrate).build()
            )
            .setEnableFallback(true)
            .build()
        val transformer = Transformer.Builder(context)
            .setVideoMimeType(MimeTypes.VIDEO_H264)
            .setAudioMimeType(MimeTypes.AUDIO_AAC)
            .setEncoderFactory(encoderFactory)
            // A streamable MP4 reserves 400 KB of zeros at the start for the
            // index, which would all be sent as QR codes.
            .setMuxerFactory(InAppMp4Muxer.Factory().setAttemptStreamableOutputEnabled(false))
            .addListener(object : Transformer.Listener {
                override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                    val job = jobs.remove(id) ?: return
                    sendProgress(id, 1.0)
                    job.result.success(null)
                }

                override fun onError(
                    composition: Composition,
                    exportResult: ExportResult,
                    exportException: ExportException,
                ) {
                    val job = jobs.remove(id) ?: return
                    job.output.delete()
                    job.result.error("failed", exportException.message, null)
                }
            })
            .build()

        val effects = Effects(
            if (audioChannels == 1) listOf(monoMixer()) else emptyList(),
            listOf(
                Presentation.createForShortSide(shortSide),
                FrameDropEffect.createDefaultFrameDropEffect(frameRate.toFloat()),
            ),
        )
        val item = EditedMediaItem.Builder(MediaItem.fromUri(Uri.fromFile(input)))
            .setEffects(effects)
            .build()
        val composition = Composition.Builder(EditedMediaItemSequence.Builder(item).build())
            .setHdrMode(Composition.HDR_MODE_TONE_MAP_HDR_TO_SDR_USING_OPEN_GL)
            .build()

        jobs[id] = Job(transformer, output, result)
        transformer.start(composition, output.path)
        pollProgress(id, transformer)
    }

    /** Mixes whatever the input has down to one channel. */
    private fun monoMixer() = ChannelMixingAudioProcessor().apply {
        for (inputChannels in 1..8) {
            runCatching {
                putChannelMixingMatrix(
                    ChannelMixingMatrix.createForConstantGain(inputChannels, 1)
                )
            }
        }
    }

    private fun pollProgress(id: Int, transformer: Transformer) {
        val holder = ProgressHolder()
        handler.postDelayed(object : Runnable {
            override fun run() {
                if (jobs[id]?.transformer !== transformer) return
                if (transformer.getProgress(holder) == Transformer.PROGRESS_STATE_AVAILABLE) {
                    sendProgress(id, holder.progress / 100.0)
                }
                handler.postDelayed(this, 250)
            }
        }, 250)
    }

    private fun sendProgress(id: Int, progress: Double) {
        channel.invokeMethod("progress", mapOf("id" to id, "progress" to progress))
    }

    /** The listener isn't called after cancelling, so the result is sent here. */
    private fun cancel(id: Int) {
        val job = jobs.remove(id) ?: return
        job.transformer.cancel()
        job.output.delete()
        job.result.error("cancelled", null, null)
    }
}
