# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


MINT = "#64EFC2"
MINT_LIGHT = "#8AFFDB"
WHITE = "#F5F8F7"
MUTED = "#AAB4B7"


def font(size: int, *, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    filename = "segoeuib.ttf" if bold else "segoeui.ttf"
    candidate = Path("C:/Windows/Fonts") / filename
    try:
        return ImageFont.truetype(str(candidate), size=size)
    except OSError:
        return ImageFont.load_default()


def gradient(size: tuple[int, int], start: tuple[int, int, int], end: tuple[int, int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGB", size)
    pixels = image.load()
    for y in range(height):
        for x in range(width):
            ratio = (x / max(1, width - 1) + y / max(1, height - 1)) / 2
            pixels[x, y] = tuple(round(a + (b - a) * ratio) for a, b in zip(start, end))
    return image


def icon_master() -> Image.Image:
    scale = 2
    size = 512 * scale
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle((24 * scale,) * 2 + (488 * scale,) * 2, radius=128 * scale, fill=255)
    background = gradient((size, size), (27, 42, 48), (7, 10, 14)).convert("RGBA")
    image.alpha_composite(Image.composite(background, Image.new("RGBA", (size, size)), mask))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle(
        (25 * scale, 25 * scale, 487 * scale, 487 * scale),
        radius=127 * scale,
        outline=(255, 255, 255, 28),
        width=2 * scale,
    )
    draw.arc(
        (126 * scale, 151 * scale, 386 * scale, 347 * scale),
        start=180,
        end=360,
        fill=MINT,
        width=38 * scale,
    )
    draw.line((137 * scale, 298 * scale, 375 * scale, 298 * scale), fill=WHITE, width=30 * scale)
    draw.line((166 * scale, 298 * scale, 166 * scale, 355 * scale), fill=WHITE, width=24 * scale)
    draw.line((346 * scale, 298 * scale, 346 * scale, 355 * scale), fill=WHITE, width=24 * scale)
    draw.line((137 * scale, 363 * scale, 375 * scale, 363 * scale), fill=MINT, width=28 * scale)
    draw.line((256 * scale, 108 * scale, 256 * scale, 250 * scale), fill=WHITE, width=30 * scale)
    draw.line(
        (209 * scale, 211 * scale, 256 * scale, 258 * scale, 303 * scale, 211 * scale),
        fill=WHITE,
        width=30 * scale,
        joint="curve",
    )
    return image.resize((512, 512), Image.Resampling.LANCZOS)


def add_icon(canvas: Image.Image, box: tuple[int, int, int, int], icon: Image.Image) -> None:
    width = box[2] - box[0]
    height = box[3] - box[1]
    resized = icon.resize((width, height), Image.Resampling.LANCZOS)
    canvas.alpha_composite(resized, (box[0], box[1]))


def small_tile(icon: Image.Image) -> Image.Image:
    image = gradient((440, 280), (26, 43, 48), (7, 10, 14)).convert("RGBA")
    add_icon(image, (35, 63, 189, 217), icon)
    draw = ImageDraw.Draw(image)
    draw.text((211, 89), "Media Bridge", fill=WHITE, font=font(30, bold=True))
    draw.text((213, 135), "LOCAL. SIMPLE. YOURS.", fill=MINT_LIGHT, font=font(13, bold=True))
    draw.text((213, 174), "Video and audio saved locally", fill=MUTED, font=font(13))
    return image


def large_tile(icon: Image.Image) -> Image.Image:
    image = gradient((1400, 560), (27, 48, 53), (6, 9, 13)).convert("RGBA")
    add_icon(image, (110, 70, 600, 560), icon)
    draw = ImageDraw.Draw(image)
    draw.text((650, 155), "Media Bridge", fill=WHITE, font=font(76, bold=True))
    draw.text((655, 270), "LOCAL. SIMPLE. YOURS.", fill=MINT_LIGHT, font=font(22, bold=True))
    draw.text(
        (655, 344),
        "Save permitted video and audio\ndirectly on your computer.",
        fill=MUTED,
        font=font(25),
        spacing=12,
    )
    return image


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", type=Path, required=True)
    args = parser.parse_args()
    root = args.project_root.resolve()
    extension_assets = root / "extension" / "assets"
    store_assets = root / "store-assets"
    extension_assets.mkdir(parents=True, exist_ok=True)
    store_assets.mkdir(parents=True, exist_ok=True)

    icon = icon_master()
    for size in (16, 32, 48, 128):
        icon.resize((size, size), Image.Resampling.LANCZOS).save(extension_assets / f"icon-{size}.png")
    icon.resize((300, 300), Image.Resampling.LANCZOS).save(store_assets / "media-bridge-logo-300.png")
    small_tile(icon).save(store_assets / "media-bridge-small-tile-440x280.png")
    large_tile(icon).save(store_assets / "media-bridge-large-tile-1400x560.png")
    print("Release assets created under extension/assets and store-assets.")


if __name__ == "__main__":
    main()
