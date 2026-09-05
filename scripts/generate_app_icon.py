#!/usr/bin/env python3
"""Generate a simple original Glass Stats macOS app icon (not derived from Stats)."""

from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path


def write_png(path: Path, width: int, height: int, rgba: bytes) -> None:
    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    raw = b"".join(b"\x00" + rgba[y * width * 4 : (y + 1) * width * 4] for y in range(height))
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def pixel(x: float, y: float) -> tuple[int, int, int, int]:
    # Normalized -1..1 around center.
    dx, dy = x * 2 - 1, y * 2 - 1
    r = math.hypot(dx, dy)
    # Squircle window.
    squircle = abs(dx) ** 4 + abs(dy) ** 4
    if squircle > 0.92:
        return (0, 0, 0, 0)
    edge = max(0.0, (squircle - 0.78) / 0.14)

    bg = (
        int(lerp(18, 42, (1 - dy) * 0.5)),
        int(lerp(28, 64, (1 - dy) * 0.5)),
        int(lerp(40, 78, (1 - dy) * 0.5)),
    )
    # Glass sheen.
    sheen = max(0.0, 1 - math.hypot(dx + 0.25, dy + 0.45) * 1.4)
    ring = math.exp(-((r - 0.55) ** 2) / 0.006)
    needle_angle = -0.85
    nx, ny = math.cos(needle_angle), math.sin(needle_angle)
    proj = dx * nx + dy * ny
    dist = abs(dx * ny - dy * nx)
    needle = 1.0 if 0 < proj < 0.52 and dist < 0.045 else 0.0
    hub = 1.0 if r < 0.08 else 0.0

    cr = min(255, int(bg[0] + sheen * 70 + ring * 90 + needle * 140 + hub * 180))
    cg = min(255, int(bg[1] + sheen * 90 + ring * 180 + needle * 220 + hub * 220))
    cb = min(255, int(bg[2] + sheen * 110 + ring * 200 + needle * 230 + hub * 240))
    alpha = int(255 * (1 - edge))
    return (cr, cg, cb, alpha)


def render(size: int) -> bytes:
    out = bytearray(size * size * 4)
    for y in range(size):
        for x in range(size):
            # 4x supersample for small sizes.
            acc = [0, 0, 0, 0]
            samples = 2 if size <= 32 else 1
            for sy in range(samples):
                for sx in range(samples):
                    px, py, pz, pa = pixel((x + (sx + 0.5) / samples) / size, (y + (sy + 0.5) / samples) / size)
                    acc[0] += px
                    acc[1] += py
                    acc[2] += pz
                    acc[3] += pa
            n = samples * samples
            i = (y * size + x) * 4
            out[i : i + 4] = bytes(v // n for v in acc)
    return bytes(out)


def main() -> None:
    root = Path(__file__).resolve().parents[1] / "GlassStats" / "Assets.xcassets" / "AppIcon.appiconset"
    root.mkdir(parents=True, exist_ok=True)
    sizes = {
        "icon_16.png": 16,
        "icon_32.png": 32,
        "icon_64.png": 64,
        "icon_128.png": 128,
        "icon_256.png": 256,
        "icon_512.png": 512,
        "icon_1024.png": 1024,
    }
    for name, size in sizes.items():
        write_png(root / name, size, size, render(size))
        print(f"wrote {name}")


if __name__ == "__main__":
    main()
