# blastqr_video

Re-encodes a video to H.264/AAC MP4 at a given bitrate and size, using the
platform's hardware encoder: AVFoundation on iOS and macOS, Media3 Transformer
on Android. Other platforms aren't supported (`BlastqrVideo.isSupported`).

The app decides the bitrate and size; this package only probes and encodes.
