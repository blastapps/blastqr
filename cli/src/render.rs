//! Drawing QR codes in the terminal, either with Unicode block characters
//! (works everywhere) or as images with the Kitty or iTerm2 graphics
//! protocols. Several codes can be shown at once, in a grid.

use std::fmt::Write as _;

use base64::Engine;
use base64::engine::general_purpose::STANDARD as BASE64;

use crate::qr::{self, Matrix};

/// Smallest module size, in pixels, for the image backends.
const MIN_MODULE_PX: usize = 3;

/// Lines kept free below the codes for the status line.
const STATUS_LINES: usize = 1;

/// Shown in text mode, on its own line if there's room below the codes.
const TEXT_WARNING: &str = "\x1b[33mWarning: Running in text mode. Use a terminal that \
    can show images for full speed.";

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Backend {
    /// Half blocks: 1×2 modules per cell.
    Half,
    Kitty,
    Iterm,
}

impl Backend {
    /// Picks an image protocol if the terminal is known to support one.
    pub fn detect() -> Backend {
        let var = |name| std::env::var(name).unwrap_or_default();
        let term = var("TERM");
        let program = var("TERM_PROGRAM");
        if term == "xterm-kitty"
            || term == "xterm-ghostty"
            || program == "ghostty"
            || !var("KITTY_WINDOW_ID").is_empty()
        {
            Backend::Kitty
        } else if program == "iTerm.app" || program == "WezTerm" {
            Backend::Iterm
        } else {
            Backend::Half
        }
    }

    pub fn is_text(self) -> bool {
        self == Backend::Half
    }

    /// Quiet zone around each code, in modules. Two is less than the spec's
    /// four but decoders handle it, and terminal space is tight.
    fn quiet(self) -> usize {
        if self.is_text() { 2 } else { 4 }
    }

    /// One code plus its quiet zone, in modules per side.
    fn tile(self, version: u8) -> usize {
        qr::modules(version) + 2 * self.quiet()
    }
}

#[derive(Clone, Copy, Debug)]
pub struct TermSize {
    pub cols: usize,
    pub rows: usize,
    /// Window size in pixels, 0 if the terminal doesn't report it.
    pub width_px: usize,
    pub height_px: usize,
}

impl TermSize {
    pub fn query() -> std::io::Result<TermSize> {
        let size = crossterm::terminal::window_size()?;
        Ok(TermSize {
            cols: size.columns as usize,
            rows: size.rows as usize,
            width_px: size.width as usize,
            height_px: size.height as usize,
        })
    }

    pub fn has_pixels(&self) -> bool {
        self.width_px > 0 && self.height_px > 0
    }

    fn code_rows(&self) -> usize {
        self.rows.saturating_sub(STATUS_LINES)
    }
}

/// Where the codes go on screen.
#[derive(Clone, Copy, Debug)]
struct Placement {
    /// Top-left cell, 0-based.
    col: usize,
    row: usize,
    /// Codes across and down.
    grid: (usize, usize),
    /// Pixels per module on screen, rounded down (image backends only).
    module_px: usize,
    /// Cells covered, across and down.
    cells: (usize, usize),
}

/// Where `count` codes of `version` go, if they fit. Text backends prefer the
/// widest grid that fits; image backends the one with the biggest modules.
fn place(backend: Backend, version: u8, count: usize, term: TermSize) -> Option<Placement> {
    let tile = backend.tile(version);
    let grids = (1..=count)
        .rev()
        .map(|across| (across, count.div_ceil(across)));
    if backend.is_text() {
        grids.into_iter().find_map(|grid| {
            let cols = grid.0 * tile;
            let rows = (grid.1 * tile).div_ceil(2);
            (cols <= term.cols && rows <= term.code_rows()).then(|| Placement {
                col: (term.cols - cols) / 2,
                row: (term.code_rows() - rows) / 2,
                grid,
                module_px: 0,
                cells: (cols, rows),
            })
        })
    } else {
        let cell_w = term.width_px / term.cols.max(1);
        let cell_h = term.height_px / term.rows.max(1);
        if cell_w == 0 || cell_h == 0 {
            return None;
        }
        // Kitty images are scaled to fill whole cells, so modules needn't be
        // whole pixels there. iTerm2 draws them at their own size.
        let scaled = backend == Backend::Kitty;
        let (width, height) = if scaled {
            (cell_w * term.cols, cell_h * term.code_rows())
        } else {
            (term.width_px, cell_h * term.code_rows())
        };
        let (grid, px) = grids
            .map(|grid| {
                let px = (width as f64 / (grid.0 * tile) as f64)
                    .min(height as f64 / (grid.1 * tile) as f64);
                (grid, if scaled { px } else { px.floor() })
            })
            .max_by(|a, b| a.1.total_cmp(&b.1))?;
        if px < MIN_MODULE_PX as f64 {
            return None;
        }
        let (w, h) = ((grid.0 * tile) as f64 * px, (grid.1 * tile) as f64 * px);
        let (cols, rows) = if scaled {
            ((w / cell_w as f64) as usize, (h / cell_h as f64) as usize)
        } else {
            ((w as usize).div_ceil(cell_w), (h as usize).div_ceil(cell_h))
        };
        Some(Placement {
            col: term.cols.saturating_sub(cols) / 2,
            row: term.code_rows().saturating_sub(rows) / 2,
            grid,
            module_px: px as usize,
            cells: (cols, rows),
        })
    }
}

/// Largest QR version at which `count` codes fit the terminal.
pub fn largest_version(backend: Backend, count: usize, term: TermSize) -> Option<u8> {
    (1..=qr::MAX_VERSION)
        .rev()
        .find(|&v| place(backend, v, count, term).is_some())
}

/// Terminal size, in cells, needed for one code of `version` (text backends).
pub fn needed_cells(backend: Backend, version: u8) -> (usize, usize) {
    let tile = backend.tile(version);
    (tile, tile.div_ceil(2) + STATUS_LINES)
}

/// All codes of a frame laid out in a grid, quiet zones included.
struct Canvas {
    width: usize,
    height: usize,
    dark: Vec<bool>,
}

impl Canvas {
    fn new(codes: &[Matrix], grid: (usize, usize), quiet: usize) -> Canvas {
        let tile = codes[0].size + 2 * quiet;
        let (width, height) = (grid.0 * tile, grid.1 * tile);
        let mut dark = vec![false; width * height];
        for (i, m) in codes.iter().enumerate() {
            let (top, left) = ((i / grid.0) * tile + quiet, (i % grid.0) * tile + quiet);
            for row in 0..m.size {
                for col in 0..m.size {
                    dark[(top + row) * width + left + col] = m.is_dark(row, col);
                }
            }
        }
        Canvas {
            width,
            height,
            dark,
        }
    }

    /// Outside the canvas counts as light.
    fn is_dark(&self, y: usize, x: usize) -> bool {
        y < self.height && x < self.width && self.dark[y * self.width + x]
    }
}

pub struct Renderer {
    backend: Backend,
    version: u8,
    max_codes: usize,
    placement: Option<Placement>,
    codes: usize,
    rows: usize,
    cols: usize,
}

impl Renderer {
    pub fn new(backend: Backend, version: u8, max_codes: usize, term: TermSize) -> Renderer {
        let mut r = Renderer {
            backend,
            version,
            max_codes,
            placement: None,
            codes: 1,
            rows: 0,
            cols: 0,
        };
        r.resize(term);
        r
    }

    /// Recomputes the layout: as many codes as fit, up to the maximum.
    pub fn resize(&mut self, term: TermSize) {
        self.rows = term.rows;
        self.cols = term.cols;
        self.placement = None;
        self.codes = 1;
        for count in (1..=self.max_codes).rev() {
            if let Some(p) = place(self.backend, self.version, count, term) {
                self.placement = Some(p);
                self.codes = count;
                break;
            }
        }
    }

    /// How many codes each frame shows.
    pub fn codes(&self) -> usize {
        self.codes
    }

    pub fn is_text(&self) -> bool {
        self.backend.is_text()
    }

    /// Escape codes that draw one frame plus the status line. Wrapped in
    /// synchronized output so half-drawn codes are never shown.
    pub fn frame(&self, codes: &[Matrix], status: &str) -> Vec<u8> {
        let mut out = String::from("\x1b[?2026h");
        match self.placement {
            None => {
                out.push_str("\x1b[2J\x1b[1;1H");
                out.push_str(&truncate(
                    "Terminal too small for this code. Enlarge it or shrink the font.",
                    self.cols,
                ));
            }
            Some(p) => {
                let canvas = Canvas::new(codes, p.grid, self.backend.quiet());
                match self.backend {
                    Backend::Half => self.text(&mut out, &canvas, p),
                    Backend::Kitty => kitty(&mut out, &canvas, p),
                    Backend::Iterm => iterm(&mut out, &canvas, p),
                }
            }
        }
        let mut status = status.to_string();
        if self.backend.is_text() {
            let free_line = self
                .placement
                .is_some_and(|p| p.row + p.cells.1 < self.rows - STATUS_LINES);
            if free_line {
                let _ = write!(
                    out,
                    "\x1b[{};1H\x1b[2K{}\x1b[0m",
                    self.rows - 1,
                    truncate(TEXT_WARNING, self.cols)
                );
            } else {
                status = format!("{TEXT_WARNING}\x1b[0m · {status}");
            }
        }
        let _ = write!(
            out,
            "\x1b[{};1H\x1b[2K{}\x1b[0m",
            self.rows,
            truncate(&status, self.cols)
        );
        out.push_str("\x1b[?2026l");
        out.into_bytes()
    }

    /// Escape codes that remove anything this renderer left behind.
    pub fn cleanup(&self) -> &'static str {
        match self.backend {
            Backend::Kitty => "\x1b_Ga=d,d=A,q=2\x1b\\",
            _ => "",
        }
    }

    fn text(&self, out: &mut String, canvas: &Canvas, p: Placement) {
        // Fixed palette entries 16 (black) and 231 (white), not the theme's
        // colors, which might be inverted or tinted. Terminal.app has no
        // 24-bit color, but every terminal has these.
        // Black cells swap the colors with reverse video, which is shorter
        // to send than a color change.
        const BG_WHITE: &str = "\x1b[27m";
        const BG_BLACK: &str = "\x1b[7m";
        // Background fills the cell exactly, but block glyphs come from the
        // font and may not: in Terminal.app the glyph box is shorter than the
        // line and sits at its bottom, so ▀ is drawn too low while ▄ is about
        // right. So the top of each cell is always background, and only the
        // bottom half is ever drawn as a glyph.
        out.push_str("\x1b[38;5;16;48;5;231m");
        let mut bg_black = None;
        for line in 0..canvas.height.div_ceil(2) {
            let _ = write!(out, "\x1b[{};{}H", p.row + line + 1, p.col + 1);
            for x in 0..canvas.width {
                let black = canvas.is_dark(line * 2, x);
                let glyph = if canvas.is_dark(line * 2 + 1, x) == black {
                    ' '
                } else {
                    '▄'
                };
                if bg_black != Some(black) {
                    out.push_str(if black { BG_BLACK } else { BG_WHITE });
                    bg_black = Some(black);
                }
                out.push(glyph);
            }
        }
        out.push_str("\x1b[0m");
    }
}

/// Kitty images go out at 2 pixels per module and the terminal scales them up
/// to fill `p.cells`, which keeps each frame small to send and decode. Scaling
/// filters linearly, softening edges by half a source pixel; 1 pixel per
/// module looked visibly blurry.
fn kitty(out: &mut String, canvas: &Canvas, p: Placement) {
    let png = BASE64.encode(png(canvas, 2));
    let _ = write!(out, "\x1b[{};{}H", p.row + 1, p.col + 1);
    // Replace the previous frame: free it, then transmit and place.
    out.push_str("\x1b_Ga=d,d=I,i=1,q=2\x1b\\");
    let chunks: Vec<&str> = png
        .as_bytes()
        .chunks(4096)
        .map(|c| std::str::from_utf8(c).unwrap())
        .collect();
    for (i, chunk) in chunks.iter().enumerate() {
        let more = (i + 1 < chunks.len()) as u8;
        if i == 0 {
            let _ = write!(
                out,
                "\x1b_Ga=T,f=100,i=1,q=2,C=1,c={},r={},m={more};{chunk}\x1b\\",
                p.cells.0, p.cells.1
            );
        } else {
            let _ = write!(out, "\x1b_Gm={more};{chunk}\x1b\\");
        }
    }
}

fn iterm(out: &mut String, canvas: &Canvas, p: Placement) {
    let png = png(canvas, p.module_px);
    let _ = write!(
        out,
        "\x1b[{};{}H\x1b]1337;File=inline=1;size={};width={}px;height={}px;\
         preserveAspectRatio=0;doNotMoveCursor=1:{}\x07",
        p.row + 1,
        p.col + 1,
        png.len(),
        canvas.width * p.module_px,
        canvas.height * p.module_px,
        BASE64.encode(&png),
    );
}

/// The canvas as a 1-bit grayscale PNG with `module_px` pixels per module.
fn png(canvas: &Canvas, module_px: usize) -> Vec<u8> {
    let (width, height) = (canvas.width * module_px, canvas.height * module_px);
    let stride = width.div_ceil(8);
    let mut pixels = vec![0xFFu8; stride * height];
    for y in 0..height {
        for x in 0..width {
            if canvas.is_dark(y / module_px, x / module_px) {
                pixels[y * stride + x / 8] &= !(0x80 >> (x % 8));
            }
        }
    }
    let mut png = Vec::new();
    let mut encoder = png::Encoder::new(&mut png, width as u32, height as u32);
    encoder.set_color(png::ColorType::Grayscale);
    encoder.set_depth(png::BitDepth::One);
    encoder.set_compression(png::Compression::Fast);
    let mut writer = encoder.write_header().expect("PNG header");
    writer.write_image_data(&pixels).expect("PNG data");
    writer.finish().expect("PNG end");
    png
}

/// The first `max` visible characters of `s`. Escape sequences such as
/// colors are kept and don't count.
fn truncate(s: &str, max: usize) -> String {
    let mut out = String::new();
    let mut visible = 0;
    let mut chars = s.chars();
    while let Some(c) = chars.next() {
        if c == '\x1b' {
            out.push(c);
            for c in chars.by_ref() {
                out.push(c);
                if c.is_ascii_alphabetic() {
                    break;
                }
            }
        } else if visible < max {
            out.push(c);
            visible += 1;
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn term(cols: usize, rows: usize) -> TermSize {
        TermSize {
            cols,
            rows,
            width_px: cols * 8,
            height_px: rows * 16,
        }
    }

    fn codes(count: usize, version: u8) -> (Vec<Vec<u8>>, Vec<Matrix>) {
        let data: Vec<Vec<u8>> = (0..count).map(|i| vec![i as u8 + 1; 40]).collect();
        let matrices = data.iter().map(|d| qr::encode(d, version)).collect();
        (data, matrices)
    }

    /// Finds and decodes every QR code in a grayscale image.
    fn scan_all(w: usize, h: usize, light: impl Fn(usize, usize) -> bool) -> Vec<Vec<u8>> {
        let mut img =
            rqrr::PreparedImage::prepare_from_greyscale(
                w,
                h,
                |x, y| {
                    if light(x, y) { 255 } else { 0 }
                },
            );
        let mut found: Vec<Vec<u8>> = img
            .detect_grids()
            .iter()
            .map(|g| {
                let mut bytes = Vec::new();
                g.decode_to(&mut bytes).unwrap();
                bytes
            })
            .collect();
        found.sort();
        found
    }

    #[test]
    fn half_blocks_pick_the_largest_version_that_fits() {
        // Version 40 is 177 modules + 4 quiet = 181 wide, 91 lines + status.
        let b = Backend::Half;
        assert_eq!(largest_version(b, 1, term(181, 92)), Some(40));
        assert_eq!(largest_version(b, 1, term(180, 92)), Some(39));
        assert_eq!(largest_version(b, 1, term(80, 24)), Some(6));
        assert_eq!(largest_version(b, 1, term(20, 10)), None);
    }

    #[test]
    fn several_codes_go_side_by_side_first() {
        // Three version-10 tiles (61 modules) across, as half blocks.
        let p = place(Backend::Half, 10, 3, term(183, 32)).unwrap();
        assert_eq!(p.grid, (3, 1));
        // Not wide enough: two rows.
        let p = place(Backend::Half, 10, 3, term(130, 63)).unwrap();
        assert_eq!(p.grid, (2, 2));
        // Too small for two: shows fewer.
        let r = Renderer::new(Backend::Half, 10, 4, term(70, 40));
        assert_eq!(r.codes(), 1);
    }

    #[test]
    fn kitty_fills_the_width_with_fractional_modules() {
        let t = TermSize {
            cols: 216,
            rows: 60,
            width_px: 3456,
            height_px: 2160,
        };
        // 4 tiles of 185 modules: 4.67 px each, not 4.
        let p = place(Backend::Kitty, 40, 8, t).unwrap();
        assert_eq!((p.grid, p.cells.0), ((4, 2), 216));
        let p = place(Backend::Iterm, 40, 8, t).unwrap();
        assert_eq!((p.grid, p.module_px), ((4, 2), 4));
    }

    #[test]
    fn truncate_skips_colors() {
        assert_eq!(
            truncate("\x1b[33mwarn\x1b[39m ok", 6),
            "\x1b[33mwarn\x1b[39m o"
        );
        assert_eq!(truncate("abc", 2), "ab");
    }

    #[test]
    fn png_scans() {
        let (data, matrices) = codes(2, 4);
        let p = place(Backend::Kitty, 4, 2, term(200, 60)).unwrap();
        let png = png(&Canvas::new(&matrices, p.grid, 4), 3);
        let mut reader = png::Decoder::new(std::io::Cursor::new(png))
            .read_info()
            .unwrap();
        let (w, h) = (reader.info().width as usize, reader.info().height as usize);
        let mut buf = vec![0; reader.output_buffer_size().unwrap()];
        reader.next_frame(&mut buf).unwrap();
        let stride = w.div_ceil(8);
        let found = scan_all(w, h, |x, y| {
            buf[y * stride + x / 8] & (0x80 >> (x % 8)) != 0
        });
        assert_eq!(found, data);
    }

    /// Plays the escape codes onto a pixel grid, 2×4 pixels per cell.
    fn replay(out: &str, t: TermSize) -> (usize, usize, Vec<bool>) {
        let (w, h) = (t.cols * 2, t.rows * 4);
        let mut light = vec![false; w * h];
        let (mut row, mut col, mut fg_light, mut bg_light) = (0, 0, true, false);
        let mut reverse = false;
        let mut chars = out.chars();
        while let Some(c) = chars.next() {
            if c == '\x1b' {
                chars.next();
                let mut seq = String::new();
                let end = loop {
                    let c = chars.next().unwrap();
                    if c.is_ascii_alphabetic() {
                        break c;
                    }
                    seq.push(c);
                };
                match end {
                    'H' => {
                        let (r, c) = seq.split_once(';').unwrap();
                        row = r.parse::<usize>().unwrap() - 1;
                        col = c.parse::<usize>().unwrap() - 1;
                    }
                    'm' => {
                        let p: Vec<&str> = seq.split(';').collect();
                        for i in 0..p.len() {
                            match (p[i], p.get(i + 2)) {
                                ("7", _) if p.len() == 1 => reverse = true,
                                ("27", _) => reverse = false,
                                ("38", Some(v)) => fg_light = *v != "16",
                                ("48", Some(v)) => bg_light = *v != "16",
                                _ => {}
                            }
                        }
                    }
                    _ => {}
                }
                continue;
            }
            // The last two lines are the warning and the status.
            if row < t.rows - STATUS_LINES - 1 {
                // Lit quarters: 1 top left, 2 top right, 4 bottom left, 8 bottom right.
                let glyph = match c {
                    ' ' => 0,
                    '▀' => 3,
                    '▄' => 12,
                    '█' => 15,
                    _ => panic!("unexpected glyph {c:?}"),
                };
                let (fg_light, bg_light) = if reverse {
                    (bg_light, fg_light)
                } else {
                    (fg_light, bg_light)
                };
                for (bit, (dx, dy)) in [(0, 0), (1, 0), (0, 2), (1, 2)].into_iter().enumerate() {
                    for sub in 0..2 {
                        light[(row * 4 + dy + sub) * w + col * 2 + dx] = if glyph & (1 << bit) != 0
                        {
                            fg_light
                        } else {
                            bg_light
                        };
                    }
                }
            }
            col += 1;
        }
        (w, h, light)
    }

    #[test]
    fn half_blocks_scan() {
        let t = term(140, 40);
        let (data, matrices) = codes(3, 3);
        let r = Renderer::new(Backend::Half, 3, 3, t);
        assert_eq!(r.codes(), 3);
        let out = String::from_utf8(r.frame(&matrices, "status")).unwrap();
        let (w, h, light) = replay(&out, t);
        // Off-canvas cells were never drawn: treat as light.
        let found = scan_all(w, h, |x, y| light[y * w + x] || y >= (t.rows - 2) * 4);
        assert_eq!(found, data);
        assert!(!out.contains('▀'));
        assert!(out.contains(TEXT_WARNING));
    }
}
