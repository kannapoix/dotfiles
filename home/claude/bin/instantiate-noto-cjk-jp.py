"""Pin Noto Sans CJK JP to static Regular and Bold faces.

nixpkgs ships the variable collection with a single Thin instance, and resvg
then ignores font-weight, so every label renders at weight 100. Scope diagrams
use weight 400 and 700. Write two static fonts into DEST.
"""

import sys

from fontTools.ttLib import TTCollection, TTFont
from fontTools.varLib.instancer import instantiateVariableFont


def family(font):
    for rec in font["name"].names:
        if rec.nameID == 1 and rec.langID == 0x409:
            return rec.toUnicode()
    return ""


def pin(src, weight, dest):
    # Face 0 of the nixpkgs collection is Noto Sans CJK JP. A reorder upstream
    # would silently ship another language, so refuse that.
    font = TTCollection(src).fonts[0]
    if family(font) != "Noto Sans CJK JP":
        got = family(font)
        sys.exit(
            f"expected the first face to be Noto Sans CJK JP, got {got!r}")
    # resvg does not draw a pinned CFF2 font. Downgrade to CFF, which it does.
    instantiateVariableFont(
        font, {"wght": weight}, inplace=True, updateFontNames=True,
        downgradeCFF2=True, static=True)
    font["OS/2"].usWeightClass = weight
    font.save(dest)
    saved = TTFont(dest)
    if saved["OS/2"].usWeightClass != weight or "CFF " not in saved:
        sys.exit(f"{dest} is not a CFF font of weight {weight}")


def main(argv):
    if len(argv) != 3:
        print(
            "usage: instantiate-noto-cjk-jp.py SRC.ttc DEST_DIR",
            file=sys.stderr)
        return 1
    src, dest = argv[1], argv[2]
    pin(src, 400, f"{dest}/NotoSansCJKjp-Regular.otf")
    pin(src, 700, f"{dest}/NotoSansCJKjp-Bold.otf")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
