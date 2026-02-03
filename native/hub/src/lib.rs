
mod signals;
mod functions;

use rinf::{dart_shutdown, write_interface};
use tokio::spawn;

write_interface!();

// You can go with any async library, not just `tokio`.
#[tokio::main(flavor = "current_thread")]
async fn main() {
    // Spawn concurrent tasks.
    // Always use non-blocking async functions like `tokio::fs::File::open`.
    // If you must use blocking code, use `tokio::task::spawn_blocking`
    // or the equivalent provided by your async library.
    spawn(functions::listen_for_config());
    spawn(functions::stream_encode_data());
    spawn(functions::decode_chunk());

    // Keep the main function running until Dart shutdown.
    dart_shutdown().await;
}
