# BlastQR transfer protocol, version 2

BlastQR sends a file from one device's screen to another device's camera as a
stream of QR codes. This document describes what's in those QR codes and what
each side has to do with them.

## Overview

The link only goes one way. The receiver can't ask for a frame it missed, so
the sender uses RaptorQ, a fountain code. The data is split into K source
packets, and the sender can make as many extra repair packets as it wants.
Any K or so different packets are enough to rebuild the data, in any order.

The sender shows each packet once, in its own QR code, and never repeats one.
A receiver that misses frames just takes longer.

The data that RaptorQ carries is called the transfer object. It contains the
file and its name, optionally gzipped, and optionally encrypted. Several files
are sent as one zip, in a single transfer.

## Frame

One QR code holds one frame: a 14-byte header followed by one RaptorQ packet.
All integers are big-endian.

```
offset  size  field
0       3     signature       "bQR" (0x62 0x51 0x52)
3       1     version         2
4       1     flags
5       1     kind            0 = file
6       2     session id      random per transfer, 1 to 65535
8       4     transfer length length of the transfer object
12      2     symbol size     RaptorQ symbol size T
14      4+T   RaptorQ packet
```

A frame is always exactly 14 + 4 + T bytes. With T = 2928 that's 2946 bytes,
which fits in a version 40 QR code at error correction level L (2953 bytes).

QR codes use error correction level L. RaptorQ already handles lost frames, so
the QR code only needs to survive a few bad pixels.

### Signature and version

Every frame starts with `bQR`. Future versions keep the signature and change
the version byte. A receiver can then tell a newer BlastQR stream (ask the user
to update) from a QR code that isn't BlastQR at all.

### Flags

| bit | meaning |
|---|---|
| 0x01 | the transfer object is gzipped |
| 0x02 | the transfer object is encrypted |
| 0x04, 0x08 | unused, must be understood |
| 0x10 to 0x80 | unused, can be ignored |

The low four bits must be understood. A receiver that finds an unknown one
there must refuse the stream. Unknown bits in the high four can be ignored.

### Kind

What's being sent. Only 0 (a file) exists today. Receivers treat unknown kinds
as files, so new kinds don't break older receivers.

### Session id

A new random value for every transfer. Together with the transfer length,
symbol size, flags and kind, it identifies a transfer. These five values are
called the stream key.

## RaptorQ packet

```
offset  size  field
0       1     SBN   source block number
1       3     ESI   encoding symbol id
4       T     symbol data
```

If the ESI is lower than the block's number of source symbols, the packet is a
source packet. Otherwise it's a repair packet.

Both sides build RaptorQ with the default parameters of the `raptorq` crate,
`ObjectTransmissionInformation::with_defaults(transfer length, T)`. That way
the receiver can work out the block layout from the header alone. Large
transfers are split into blocks of at most 56,403 symbols.

T is a multiple of 8. The reference sender uses T between 96 and 2928.

### Packet order

The sender first sends all source packets, block by block. After that it
sends new repair packets forever, one per block in turn: block 0 repair 0,
block 1 repair 0, and so on, then block 0 repair 1. The ESI has 24 bits, so
repair ids would only start repeating after about 16 million repair packets
per block.

## Transfer object

```
offset  size  field
0       2     metadata length M
2       M     metadata entries
2+M     ...   file content
```

Each metadata entry is a 1-byte tag, a 2-byte length and the value.

| tag | value |
|---|---|
| 1 | file name with extension, UTF-8, at most 255 bytes |
| 2 | empty. The content is a bundle of several files (see below) |

Receivers skip tags they don't know, so new metadata can be added without a
new version.

The sender then applies, in this order:

1. gzip, if it makes the data smaller (flag 0x01)
2. encryption, if the user chose it (flag 0x02)

The transfer length in the header is the size of the final result.

The file name is inside the transfer object, so the receiver only learns it at
the end. When the transfer is encrypted, the name is encrypted too.

## Bundles

To send several files, the sender puts them in a zip and sends that as the
content, with metadata tag 2 and a name like `blastqr-20261025-143000.zip`.
The zip entries are stored without compression; gzip on the whole transfer
does the compressing. Entry names are file names without folders, unique
within the zip.

A receiver that knows tag 2 saves each entry as a separate file. It only
extracts zips whose entries are all stored without compression, so the files
can't be bigger than the zip. Otherwise, or if the zip can't be read, it saves
the zip as one file. A receiver that doesn't know tag 2 also saves the zip.

## Encryption

When flag 0x02 is set, the transfer object is an encrypted envelope:

```
offset  size  field
0       1     envelope version, 1
1       1     key derivation, 1 = Argon2id
2       4     Argon2id memory in KiB
6       1     Argon2id iterations
7       1     Argon2id parallelism
8       16    salt
24      12    nonce
36      n+16  ChaCha20-Poly1305 ciphertext and tag
```

The key is Argon2id(password, salt), 32 bytes. The first 36 bytes are passed
as associated data, so changing any of them makes decryption fail. Salt and
nonce are random for every transfer.

The reference sender uses 64 MiB of memory, 3 iterations and parallelism 1.
Receivers must refuse an envelope that asks for more than 256 MiB, or for
iterations or parallelism outside 1 to 10 and 1 to 4. Without these limits a
fake stream could make the receiver run out of memory.

Encryption adds 52 bytes. The header, and so the size of the transfer, can
still be seen.

### Password

The password is never sent in a frame. The sender shows it, and the receiver
types it in.

By default the sender makes a random password of 12 characters from the
Crockford base32 alphabet (`0-9`, `A-Z` without I, L, O and U), shown in groups
of four: `K7M2-QX9P-4RTA`. That's 60 bits.

Before deriving the key, both sides normalize the password:

- If, without dashes and spaces, it's 12 characters from that alphabet (in any
  case, reading O as 0 and I or L as 1), the key is derived from the 12
  characters in upper case, without dashes.
- Anything else is a custom password and is only trimmed.

## Limits

| limit | value |
|---|---|
| file content | about 4 GB (2³² − 1 − 1024 bytes) |
| symbols per transfer | 1,500,000 |
| symbol size | at least 64 and a multiple of 8 |
| metadata | 1024 bytes reserved |

The symbol limit exists because the RaptorQ decoder reserves memory for every
symbol when it's created. It only matters with small QR codes: with T = 96 it
limits files to about 144 MB. With T = 2928 it allows about 4.3 GB.

## Receiving

### Checking each code

| the code | the receiver |
|---|---|
| doesn't start with `bQR` | treats it as an ordinary QR code |
| has a version above 2 | asks the user to update |
| has an unknown must-understand flag | asks the user to update |
| has a version below 2, or the wrong length | ignores it |
| is a valid version 2 frame | decodes it |

The receiver also ignores frames whose symbol size is below 64 or not a
multiple of 8, whose transfer length is below 2, or that would need more than
1,500,000 symbols. A real sender never sends these. The checks stop a fake
frame from making the RaptorQ decoder allocate too much memory or crash.

### One transfer at a time

The first valid frame sets the stream key, and the decoder is built for it.

- Frames with another stream key are ignored while the current transfer is
  still arriving, for example when a second sender is in view.
- Once the current transfer has had no frames for 1.5 seconds, a frame with a
  new stream key starts a new transfer.
- Packets for a block that doesn't exist are dropped.

The camera reads the same QR code several times, so the receiver skips packets
it already has, using the SBN and ESI.

### Rebuilding the file

When RaptorQ has enough packets, the receiver:

1. decrypts the transfer object, if flag 0x02 is set. A wrong password can be
   retried without scanning again.
2. gunzips it, if flag 0x01 is set. It stops once the content passes the 4 GB
   limit, so a small gzip stream can't expand into a huge file.
3. reads the metadata, then writes the content to a file, or extracts it if
   it's a bundle.

File names from the sender, including zip entry names, are not trusted. The receiver keeps only the last
path segment, removes control and forbidden characters and leading dots, and
cuts it to 200 bytes. If nothing is left, the name is `file`.

## Completion tone

Sound is the only way back from the receiver to the sender. Once all the data
has arrived, the receiver can play 880 Hz for 250 ms followed by 1320 Hz for
250 ms. It plays before the file is saved and before any password is asked, so
it means "you can stop showing codes", not "the file is saved".

The sender can listen with its microphone (16 kHz, 100 ms Goertzel windows). It
waits for 880 Hz, then for 1320 Hz within 700 ms after the 880 Hz tone has
stopped. Waiting for the gap avoids false alarms from the receiver's shorter
per-packet sounds, which can contain both frequencies at once.

The tone is optional on both sides.

## Extending the protocol

| to add | use | older receivers |
|---|---|---|
| a new type of content | a new kind | receive it as a file |
| optional information about the stream | a flag from 0x10 to 0x80 | ignore it |
| something that changes how the data must be read | flag 0x04 or 0x08 | ask to update |
| more metadata | a new metadata tag | skip it |
| a different header layout | a new version | ask to update |
| other encryption settings or ciphers | a new envelope version or key derivation id | fail to decrypt |

Receivers from before encryption was added see flag 0x02 as unknown and ask to
update.

## Known limitations

- There's no checksum of the whole file. gzipped transfers are covered by
  gzip's CRC and encrypted ones by the authentication tag, but a plain transfer
  that isn't gzipped has no check.
- Both sides rely on the `raptorq` crate's default block layout. Sending the
  full 12-byte RaptorQ configuration would remove that, at 10 more bytes per
  frame.
- The size of an encrypted transfer can be seen.

## Reference implementation

The frame and transfer object are in `lib/model/`, the sender in
`lib/features/send/`, the receiver in `lib/features/scan/` and the password
handling in `lib/crypto/`. RaptorQ comes from `../raptorq_flutter` (Rust crate
`raptorq` 1.8.1) and encryption from `../blastqr_crypto`.
