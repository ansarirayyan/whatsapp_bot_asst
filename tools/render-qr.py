#!/usr/bin/env python3
"""
render-qr.py  –  Read /tmp/wa_paircode.txt and write /tmp/wa_pairqr.png.

The pairing code is a WhatsApp linking credential.
NEVER send it to an external QR service — all rendering is done locally.

Usage:
    uv run --with "qrcode[pil]" render-qr.py
  or (inside the tools venv):
    python render-qr.py
"""

import sys
import pathlib

CODE_FILE = pathlib.Path("/tmp/wa_paircode.txt")
OUT_FILE = pathlib.Path("/tmp/wa_pairqr.png")


def main() -> int:
    if not CODE_FILE.exists():
        print(f"ERROR: {CODE_FILE} not found — bridge has not emitted a QR code yet.",
              file=sys.stderr)
        return 1

    code = CODE_FILE.read_text().strip()
    if not code:
        print(f"ERROR: {CODE_FILE} is empty.", file=sys.stderr)
        return 1

    try:
        import qrcode
        from PIL import Image  # noqa: F401 — ensures Pillow is present for PNG output
    except ImportError as exc:
        print(f"ERROR: missing dependency — {exc}\n"
              "Install with:  pip install 'qrcode[pil]'", file=sys.stderr)
        return 1

    qr = qrcode.QRCode(
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(code)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    img.save(str(OUT_FILE))

    print(f"QR PNG written to {OUT_FILE}  ({OUT_FILE.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
