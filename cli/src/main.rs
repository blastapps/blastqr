use std::io::{self, Write};
use std::path::PathBuf;
use std::process::ExitCode;
use std::sync::mpsc::{Receiver, sync_channel};
use std::time::{Duration, Instant};

use clap::Parser;
use crossterm::event::{self, Event, KeyCode, KeyEventKind, KeyModifiers};
use crossterm::{cursor, execute, terminal};

use blastqr::protocol::{self, TransferObject};
use blastqr::qr::{self, Matrix};
use blastqr::render::{self, Backend, Renderer, TermSize};
use blastqr::stream::PacketStream;
use blastqr::{bundle, password};

/// Send files to the BlastQR app by showing a stream of QR codes in the
/// terminal. Point the app's scanner at the screen.
#[derive(Parser)]
#[command(version)]
struct Args {
    /// Files to send. Several files are sent together as one zip, which the
    /// app unpacks.
    #[arg(required = true)]
    files: Vec<PathBuf>,

    /// Frames per second.
    #[arg(long, default_value_t = 20, value_parser = clap::value_parser!(u32).range(1..=60))]
    fps: u32,

    /// Draw with Unicode block characters even if the terminal can show images.
    #[arg(short, long)]
    unicode: bool,

    /// Draw with Unicode quadrant blocks: 2×2 modules per character, so codes
    /// need half the columns. Modules come out tall and narrow.
    #[arg(short, long)]
    dense: bool,

    /// Show up to this many codes per frame, side by side, each carrying
    /// different data. Without --mtu, codes are sized so this many fit.
    #[arg(short, long, default_value_t = 1, value_parser = clap::value_parser!(u32).range(1..=12))]
    codes: u32,

    /// Encrypt with a generated code, shown below the QR code.
    #[arg(short, long, conflicts_with = "password")]
    encrypt: bool,

    /// Encrypt with a password of your choice (asked for at the start).
    #[arg(short, long)]
    password: bool,

    /// File name the receiver sees (default: the file's own name, or
    /// blastqr-<date>-<time>.zip for several files).
    #[arg(long)]
    name: Option<String>,

    /// Bytes of file data per QR code (default: as much as fits the terminal).
    #[arg(long, value_parser = clap::value_parser!(u16).range(protocol::MIN_SYMBOL_SIZE as i64..=protocol::MAX_SYMBOL_SIZE as i64))]
    mtu: Option<u16>,

    /// Don't try to gzip the file.
    #[arg(long)]
    no_gzip: bool,

    /// Don't ask for confirmation (e.g. before sending more than 10 MB).
    #[arg(short, long)]
    yes: bool,
}

/// Sending more than this asks for confirmation.
const CONFIRM_BYTES: u64 = 10_000_000;

fn main() -> ExitCode {
    match run(Args::parse()) {
        Ok(()) => ExitCode::SUCCESS,
        Err(message) => {
            eprintln!("blastqr: {message}");
            ExitCode::FAILURE
        }
    }
}

fn run(args: Args) -> Result<(), String> {
    let term = TermSize::query().map_err(|e| format!("not a terminal: {e}"))?;
    let backend = if args.dense {
        Backend::Quadrant
    } else if args.unicode || !term.has_pixels() {
        Backend::Half
    } else {
        Backend::detect()
    };
    let codes = args.codes as usize;
    let max_symbol_size = max_symbol_size(args.mtu, backend, codes, term)?;

    // Checked from file sizes alone, before anything is read or zipped.
    let total = total_size(&args.files)?;
    if total > CONFIRM_BYTES && !args.yes {
        let version = qr::version_for(max_symbol_size + protocol::FRAME_OVERHEAD)
            .expect("symbol size fits version 40");
        let per_frame = Renderer::new(backend, version, codes, term).codes();
        let needed = (total as usize).div_ceil(max_symbol_size);
        let seconds = needed as f64 / (args.fps as usize * per_frame) as f64;
        let may_shrink = !args.no_gzip
            && (args.files.len() > 1
                || !protocol::is_precompressed(&args.files[0].to_string_lossy()));
        let question = format!(
            "This sends {}: about {needed} codes, at least {} at {} fps{}. Continue? [y/N] ",
            human_size(total as usize),
            human_duration(seconds),
            args.fps,
            if may_shrink {
                " (less if it compresses)"
            } else {
                ""
            },
        );
        if !confirm(&question)? {
            return Err("cancelled".into());
        }
    }

    let (password, shown_code) = if args.encrypt {
        let code = password::generate();
        (Some(code.clone()), Some(code))
    } else if args.password {
        (Some(ask_password()?), None)
    } else {
        (None, None)
    };

    eprintln!("Preparing…");
    let input = read_input(&args.files, args.name.as_deref())?;
    // A bundle has a .zip name, but its entries are stored uncompressed.
    let try_gzip = !args.no_gzip && (input.is_bundle || !protocol::is_precompressed(&input.name));
    let transfer = TransferObject::build(
        &input.name,
        input.is_bundle,
        &input.content,
        try_gzip,
        password.as_deref(),
    );
    let transfer_len = transfer.bytes.len();
    if transfer_len > u32::MAX as usize {
        return Err("file is too large (over 4 GB)".into());
    }

    // Small transfers get a smaller code than the terminal allows.
    let needed = transfer_len
        .next_multiple_of(8)
        .max(protocol::MIN_SYMBOL_SIZE);
    let symbol_size = max_symbol_size.min(needed);
    if !protocol::fits_symbol_limit(transfer_len, symbol_size) {
        return Err(
            "file is too large for this QR code size. Enlarge the terminal or pass a bigger --mtu."
                .into(),
        );
    }
    let version = qr::version_for(symbol_size + protocol::FRAME_OVERHEAD)
        .expect("symbol size fits version 40");
    let mut renderer = Renderer::new(backend, version, codes, term);

    let stream = PacketStream::new(&transfer.bytes, symbol_size as u16);
    assert_eq!(stream.symbol_size() as usize, symbol_size);
    let source_count = stream.source_count();
    let header = protocol::frame_header(
        transfer.flags(),
        protocol::random_session_id(),
        transfer_len as u32,
        symbol_size as u16,
    );
    let frames = spawn_frame_producer(stream, header, version);

    let info = Info {
        name: input.label,
        size: input.size,
        source_count,
        code: shown_code,
    };
    let shown = with_screen(|out| play(out, &mut renderer, &frames, &info, args.fps))
        .map_err(|e| format!("terminal error: {e}"))?;
    eprintln!("Showed {shown} codes ({source_count} needed at minimum).");
    Ok(())
}

/// What gets sent: one file as is, or several as a zip.
struct Input {
    /// Name the receiver sees.
    name: String,
    is_bundle: bool,
    content: Vec<u8>,
    /// For the status line: the file name, or "3 files".
    label: String,
    /// Size of the original files.
    size: usize,
}

/// Total size of the files, checking each one is a readable file and that
/// they fit a transfer.
fn total_size(paths: &[PathBuf]) -> Result<u64, String> {
    let mut total = 0u64;
    for path in paths {
        let meta =
            std::fs::metadata(path).map_err(|e| format!("can't read {}: {e}", path.display()))?;
        if meta.is_dir() {
            return Err(format!(
                "{} is a folder. Pass the files in it instead (e.g. {}/*); \
                 the app receives files without folders.",
                path.display(),
                path.display()
            ));
        }
        total += meta.len();
    }
    if total > protocol::MAX_CONTENT_BYTES {
        return Err("too large: a transfer holds at most 4 GB".into());
    }
    Ok(total)
}

fn read_input(paths: &[PathBuf], name: Option<&str>) -> Result<Input, String> {
    let mut files = vec![];
    let mut size = 0usize;
    for path in paths {
        let content =
            std::fs::read(path).map_err(|e| format!("can't read {}: {e}", path.display()))?;
        size += content.len();
        let file_name = path
            .file_name()
            .map(|n| n.to_string_lossy().into_owned())
            .unwrap_or_else(|| "file".into());
        files.push((file_name, content));
    }

    if files.len() == 1 {
        let (file_name, content) = files.pop().unwrap();
        let name = name.map_or(file_name, str::to_string);
        return Ok(Input {
            label: name.clone(),
            name,
            is_bundle: false,
            content,
            size,
        });
    }
    Ok(Input {
        name: name.map_or_else(bundle::file_name, str::to_string),
        is_bundle: true,
        label: format!("{} files", files.len()),
        content: bundle::build(&files),
        size,
    })
}

/// Largest symbol size T: the requested MTU, or the most that fits the
/// terminal. Always a multiple of 8.
fn max_symbol_size(
    mtu: Option<u16>,
    backend: Backend,
    codes: usize,
    term: TermSize,
) -> Result<usize, String> {
    let max = match mtu {
        Some(mtu) => mtu as usize,
        None => {
            let too_small = || {
                if codes > 1 {
                    return format!(
                        "{codes} codes don't fit this terminal ({}x{}). \
                         Use fewer --codes, enlarge it or shrink the font.",
                        term.cols, term.rows
                    );
                }
                let (cols, rows) = render::needed_cells(backend, 6);
                format!(
                    "terminal too small ({}x{}). Needs at least {cols}x{rows}; \
                     enlarge it or shrink the font.",
                    term.cols, term.rows
                )
            };
            let version = render::largest_version(backend, codes, term).ok_or_else(too_small)?;
            let fits = qr::capacity(version).saturating_sub(protocol::FRAME_OVERHEAD);
            if fits < protocol::MIN_SYMBOL_SIZE {
                return Err(too_small());
            }
            fits.min(protocol::MAX_SYMBOL_SIZE)
        }
    };
    Ok(max / 8 * 8)
}

fn ask_password() -> Result<String, String> {
    let read = |prompt| rpassword::prompt_password(prompt).map_err(|e| e.to_string());
    let first = read("Password: ")?;
    if first.trim().is_empty() {
        return Err("empty password".into());
    }
    if read("Repeat password: ")? != first {
        return Err("passwords don't match".into());
    }
    if password::normalize(&first).chars().count() < password::MIN_RECOMMENDED_LENGTH {
        eprintln!(
            "Warning: passwords under {} characters are easy to guess.",
            password::MIN_RECOMMENDED_LENGTH
        );
    }
    Ok(first)
}

/// Builds QR codes on a background thread, a little ahead of playback.
fn spawn_frame_producer(
    stream: PacketStream,
    header: [u8; protocol::HEADER_LEN],
    version: u8,
) -> Receiver<Matrix> {
    let (tx, rx) = sync_channel(64);
    std::thread::spawn(move || {
        for packet in stream {
            let mut frame = Vec::with_capacity(header.len() + packet.len());
            frame.extend_from_slice(&header);
            frame.extend_from_slice(&packet);
            if tx.send(qr::encode(&frame, version)).is_err() {
                return;
            }
        }
    });
    rx
}

struct Info {
    name: String,
    size: usize,
    source_count: u32,
    code: Option<String>,
}

/// Runs `f` in the alternate screen with raw input, restoring the terminal
/// afterwards even on error.
fn with_screen<T>(f: impl FnOnce(&mut io::Stdout) -> io::Result<T>) -> io::Result<T> {
    struct Restore;
    impl Drop for Restore {
        fn drop(&mut self) {
            let _ = execute!(io::stdout(), cursor::Show, terminal::LeaveAlternateScreen);
            let _ = terminal::disable_raw_mode();
        }
    }
    let mut out = io::stdout();
    terminal::enable_raw_mode()?;
    let _restore = Restore;
    execute!(
        out,
        terminal::EnterAlternateScreen,
        cursor::Hide,
        terminal::Clear(terminal::ClearType::All)
    )?;
    f(&mut out)
}

/// Shows frames until the user quits. Returns how many were shown.
fn play(
    out: &mut io::Stdout,
    renderer: &mut Renderer,
    frames: &Receiver<Matrix>,
    info: &Info,
    mut fps: u32,
) -> io::Result<u64> {
    let take = |count| -> Vec<Matrix> {
        (0..count)
            .map(|_| frames.recv().expect("frame stream is endless"))
            .collect()
    };
    let mut current = take(renderer.codes());
    let mut shown = current.len() as u64;
    let mut paused = false;
    let mut redraw = true;
    let mut due = Instant::now() + Duration::from_secs(1) / fps;

    loop {
        let now = Instant::now();
        if !paused && now >= due {
            current = take(renderer.codes());
            shown += current.len() as u64;
            redraw = true;
            // Don't try to catch up after a slow frame.
            due = (due + Duration::from_secs(1) / fps).max(now);
        }
        if redraw {
            out.write_all(&renderer.frame(&current, &status(info, shown, fps, paused)))?;
            out.flush()?;
            redraw = false;
        }

        let timeout = if paused {
            Duration::from_millis(250)
        } else {
            due.saturating_duration_since(Instant::now())
        };
        while !redraw && event::poll(timeout)? {
            match event::read()? {
                Event::Key(key) if key.kind == KeyEventKind::Press => match key.code {
                    KeyCode::Char('q') | KeyCode::Esc => return finish(out, renderer, shown),
                    KeyCode::Char('c') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                        return finish(out, renderer, shown);
                    }
                    KeyCode::Up | KeyCode::Char('+') | KeyCode::Char('=') => {
                        fps = (fps + 1).min(60);
                        redraw = true;
                    }
                    KeyCode::Down | KeyCode::Char('-') => {
                        fps = fps.saturating_sub(1).max(1);
                        redraw = true;
                    }
                    KeyCode::Char(' ') => {
                        paused = !paused;
                        due = Instant::now();
                        redraw = true;
                    }
                    _ => {}
                },
                Event::Resize(..) => {
                    execute!(out, terminal::Clear(terminal::ClearType::All))?;
                    renderer.resize(TermSize::query()?);
                    // Fewer codes may fit now; extra ones are just skipped.
                    current.truncate(renderer.codes());
                    if current.len() < renderer.codes() {
                        let more = renderer.codes() - current.len();
                        current.extend(take(more));
                        shown += more as u64;
                    }
                    redraw = true;
                }
                _ => {}
            }
        }
    }
}

fn finish(out: &mut io::Stdout, renderer: &Renderer, shown: u64) -> io::Result<u64> {
    out.write_all(renderer.cleanup().as_bytes())?;
    out.flush()?;
    Ok(shown)
}

fn status(info: &Info, shown: u64, fps: u32, paused: bool) -> String {
    let mut parts = vec![];
    if let Some(code) = &info.code {
        parts.push(format!("password {code}"));
    }
    parts.push(format!("{} ({})", info.name, human_size(info.size)));
    parts.push(format!("code {shown} / ~{}", info.source_count));
    parts.push(if paused {
        "paused".into()
    } else {
        format!("{fps} fps")
    });
    parts.push("↑↓ speed · space pause · q quit".into());
    format!(" {}", parts.join(" · "))
}

/// Asks a yes/no question on the terminal. Without a terminal to ask on,
/// the answer is no.
fn confirm(question: &str) -> Result<bool, String> {
    use std::io::IsTerminal;
    if !io::stdin().is_terminal() {
        return Err("large transfer; pass --yes to send it without asking".into());
    }
    eprint!("{question}");
    let mut answer = String::new();
    io::stdin()
        .read_line(&mut answer)
        .map_err(|e| e.to_string())?;
    Ok(matches!(answer.trim().to_lowercase().as_str(), "y" | "yes"))
}

fn human_duration(seconds: f64) -> String {
    match seconds {
        s if s < 90.0 => format!("{s:.0} seconds"),
        s if s < 90.0 * 60.0 => format!("{:.0} minutes", s / 60.0),
        s => format!("{:.1} hours", s / 3600.0),
    }
}

fn human_size(bytes: usize) -> String {
    let b = bytes as f64;
    match bytes {
        0..1_000 => format!("{bytes} B"),
        1_000..1_000_000 => format!("{:.1} KB", b / 1e3),
        1_000_000..1_000_000_000 => format!("{:.1} MB", b / 1e6),
        _ => format!("{:.2} GB", b / 1e9),
    }
}
