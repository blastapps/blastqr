# blastqr

Send files to the BlastQR app from a terminal. The files are shown as a
stream of QR codes; scan the screen with the app.

```
blastqr <file>...
```

Several files are sent together as one zip, which the app unpacks into
separate files. Folders aren't supported, since the app receives files
without folders; pass the files in them instead (`blastqr photos/*`).

## Install

With [Homebrew](https://brew.sh):

```
brew install cu-kha/tap/blastqr
```

## Options

| option | |
|---|---|
| `--fps N` | frames per second, 1 to 60 (default 20) |
| `-u`, `--unicode` | draw with Unicode block characters even if the terminal can show images |
| `-d`, `--dense` | draw with Unicode quadrant blocks, 2×2 modules per character (see below) |
| `-c`, `--codes N` | show up to N codes per frame side by side, 1 to 12 (default 1) |
| `-e`, `--encrypt` | encrypt with a generated code, shown in the status line |
| `-p`, `--password` | encrypt with your own password, asked for at the start |
| `--name NAME` | file name the receiver sees (for several files, the zip's name) |
| `--mtu N` | bytes of file data per QR code, 96 to 2928 (default: as much as fits) |
| `--no-gzip` | don't try to compress the file |
| `-y`, `--yes` | don't ask before sending more than 10 MB |

While it runs: ↑/↓ change the speed, space pauses, q quits.

## Display

In Kitty, Ghostty, iTerm2 and WezTerm the codes are drawn as images. Everywhere
else, including Terminal.app and the VS Code terminal, they're drawn with
Unicode half blocks, two modules per character cell.

With Unicode, the terminal size sets the QR code size. A full-size code
(2928 bytes per frame) needs 181×92 cells, so make the window large or the
font small. A standard 80×24 terminal holds only 112 bytes per frame.

`--dense` packs 2×2 modules into each character instead of 1×2, so a code
needs half the columns: a full-size code fits in 91×92 cells. The modules
come out twice as tall as they are wide, so the camera has less to work
with. Try both on your setup.

`--codes N` shows several different codes at once, like the app's
multiple-codes mode. Without `--mtu` the codes are sized so that N fit. If
the window gets too small, fewer are shown.

Codes are drawn mostly with background colors, so set the window opacity to
100% (Terminal.app: Settings → Profiles → Window), or what's behind the window
shows through the code.

## Protocol

Frames follow BlastQR protocol version 3 ([docs/protocol.md](../docs/protocol.md)).
Encryption comes from the
[`blastqr_envelope`](../packages/blastqr_envelope/) crate, which the app uses
too.
