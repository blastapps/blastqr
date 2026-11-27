"""Subset DNF BitBit (v1) to the Hangul syllables used in app_ko.arb.

The OFL Reserved Font Names cover the original file names; the subset is renamed.

  python build_subset.py          rebuild the subset font (needs fonttools)
  python build_subset.py --check  fail if app_ko.arb uses a syllable the
                                  subset does not contain (stdlib only)
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "DNFBitBitOTF.otf")
OUT = os.path.join(HERE, "BlastQRHangul-Bold.otf")
CHARS = os.path.join(HERE, "subset_chars.txt")
ARB = os.path.join(HERE, "..", "..", "lib", "l10n", "app_ko.arb")

FAMILY = "BlastQR Hangul"
PS_NAME = "BlastQRHangul-Bold"


def used_syllables():
    with open(ARB, encoding="utf-8") as f:
        arb = json.load(f)
    return {
        c
        for k, v in arb.items()
        if not k.startswith("@") and isinstance(v, str)
        for c in v
        if 0xAC00 <= ord(c) <= 0xD7A3
    }


def check():
    with open(CHARS, encoding="utf-8") as f:
        have = set(f.read().strip())
    missing = sorted(used_syllables() - have)
    if missing:
        print("Korean font subset is missing: " + "".join(missing))
        print("Run: python fonts/DNFBitBit/build_subset.py")
        sys.exit(1)


def build():
    from fontTools import subset
    from fontTools.ttLib import TTFont

    chars = "".join(sorted(used_syllables()))
    font = TTFont(SRC)
    sub = subset.Subsetter(subset.Options())
    sub.populate(text=chars)
    sub.subset(font)

    # Marked Bold so Flutter uses the outlines as-is for bold text instead of
    # thickening them; a single face is also picked for normal weight.
    font["OS/2"].usWeightClass = 700
    font["OS/2"].fsSelection = (font["OS/2"].fsSelection & ~(1 << 6)) | (1 << 5)
    font["head"].macStyle |= 1

    name = font["name"]
    keep = {0, 7, 8, 9, 11, 12, 13, 14}
    name.names = [r for r in name.names if r.nameID in keep]
    for name_id, value in (
        (1, FAMILY),
        (2, "Bold"),
        (3, PS_NAME),
        (4, FAMILY + " Bold"),
        (5, "Version 1.0"),
        (6, PS_NAME),
    ):
        name.setName(value, name_id, 3, 1, 0x409)
    if "CFF " in font:
        cff = font["CFF "].cff
        cff.fontNames = [PS_NAME]
        top = cff.topDictIndex[0]
        top.FullName = FAMILY + " Bold"
        top.FamilyName = FAMILY
    font.save(OUT)
    with open(CHARS, "w", encoding="utf-8") as f:
        f.write(chars + "\n")


if __name__ == "__main__":
    check() if "--check" in sys.argv else build()
