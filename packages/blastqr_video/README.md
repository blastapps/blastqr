# blastqr_video

Re-encodes a video to H.264/AAC MP4 at a given bitrate and size, using the
platform's encoder: AVFoundation on iOS and macOS, Media3 Transformer on
Android, and the `ffmpeg` command on Linux if it has an H.264 encoder (in the
Flatpak, the runtime's ffmpeg with its `codecs-extra` extension). Elsewhere
`BlastqrVideo.isSupported()` is false.

The app decides the bitrate and size; this package only probes and encodes.
