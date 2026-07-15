#!/usr/bin/env python3
"""Remove backgrounds from raw GPT images and redeploy RGBA sprites."""

from __future__ import annotations

import json
from io import BytesIO
from pathlib import Path

from PIL import Image
from rembg import remove

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / "out"


def _cover(img: Image.Image, w: int, h: int) -> Image.Image:
    scale = max(w / img.width, h / img.height)
    nw, nh = max(1, int(img.width * scale)), max(1, int(img.height * scale))
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    x = (nw - w) // 2
    y = (nh - h) // 2
    return resized.crop((x, y, x + w, y + h))


def fit_rgba(img: Image.Image, fit=None, fit_w=None, fit_h=None) -> Image.Image:
    img = img.convert("RGBA")
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
    if fit:
        img.thumbnail((fit, fit), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (fit, fit), (0, 0, 0, 0))
        canvas.paste(img, ((fit - img.width) // 2, (fit - img.height) // 2), img)
        return canvas
    if fit_w and fit_h:
        img.thumbnail((fit_w, fit_h), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (fit_w, fit_h), (0, 0, 0, 0))
        canvas.paste(img, ((fit_w - img.width) // 2, (fit_h - img.height) // 2), img)
        return canvas
    return img


def main() -> None:
    data = json.loads((Path(__file__).parent / "prompts.json").read_text(encoding="utf-8"))
    assets = list(data["assets"])
    for a in data["alphabet"]:
        assets.append(
            {
                "id": a["id"],
                "dest": a["dest"],
                "transparent": True,
                "fit_w": 48,
                "fit_h": 80,
            }
        )
    for asset in assets:
        if not asset.get("transparent"):
            continue
        raw_path = OUT / f"{asset['id']}.png"
        if not raw_path.exists():
            print("missing", asset["id"])
            continue
        print("rembg", asset["id"], "...")
        raw = Image.open(raw_path).convert("RGBA")
        cut = remove(raw)
        if isinstance(cut, bytes):
            cut = Image.open(BytesIO(cut)).convert("RGBA")
        else:
            cut = cut.convert("RGBA")
        processed = fit_rgba(cut, asset.get("fit"), asset.get("fit_w"), asset.get("fit_h"))
        dest = ROOT / asset["dest"]
        dest.parent.mkdir(parents=True, exist_ok=True)
        processed.save(dest, "PNG")
        a = processed.split()[-1]
        zeros = sum(1 for p in a.getdata() if p < 16)
        print(f"  -> {dest.name} {processed.size} transparent_px={zeros}")

    # Hedgehog copies after rembg
    import shutil

    base = ROOT / "godot/assets/textures/feuilles"
    for skin in (1, 2, 3):
        for frame in range(4, 9):
            src_frame = ((frame - 1) % 3) + 1
            src = base / f"herisson_{skin}_{src_frame}.png"
            dst = base / f"herisson_{skin}_{frame}.png"
            if src.exists():
                shutil.copy2(src, dst)
    for skin in range(4, 9):
        src_skin = ((skin - 1) % 3) + 1
        for frame in range(1, 9):
            src = base / f"herisson_{src_skin}_{frame}.png"
            dst = base / f"herisson_{skin}_{frame}.png"
            if src.exists():
                shutil.copy2(src, dst)
    print("done")


if __name__ == "__main__":
    main()
