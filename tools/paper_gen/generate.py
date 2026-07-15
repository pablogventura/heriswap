#!/usr/bin/env python3
"""Generate paper-craft assets via OpenAI Images API."""

from __future__ import annotations

import argparse
import base64
import csv
import json
import os
import shutil
import sys
import time
from pathlib import Path

from dotenv import load_dotenv
from openai import OpenAI
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / "out"
MANIFEST = OUT / "manifest.csv"


def load_key() -> str:
    load_dotenv(ROOT / ".env")
    key = os.environ.get("OPENAI_API_KEY", "").strip()
    if not key:
        sys.exit("OPENAI_API_KEY missing (.env or env)")
    return key


def gen_one(
    client: OpenAI,
    *,
    prompt: str,
    size: str,
    transparent: bool,
    quality: str,
    model: str,
) -> bytes:
    kwargs = {
        "model": model,
        "prompt": prompt,
        "size": size,
        "quality": quality,
        "output_format": "png",
    }
    if transparent:
        kwargs["background"] = "transparent"
    result = client.images.generate(**kwargs)
    b64 = result.data[0].b64_json
    if not b64:
        raise RuntimeError("empty image payload")
    return base64.b64decode(b64)


def _cover(img: Image.Image, w: int, h: int) -> Image.Image:
    scale = max(w / img.width, h / img.height)
    nw, nh = max(1, int(img.width * scale)), max(1, int(img.height * scale))
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    x = (nw - w) // 2
    y = (nh - h) // 2
    return resized.crop((x, y, x + w, y + h))


def trim_and_fit(
    img: Image.Image,
    fit: int | None,
    fit_w: int | None,
    fit_h: int | None,
    *,
    transparent: bool,
) -> Image.Image:
    if transparent:
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
    # Opaque: cover target
    if img.mode == "RGBA":
        bg = Image.new("RGB", img.size, (245, 235, 210))
        bg.paste(img, mask=img.split()[-1])
        img = bg
    else:
        img = img.convert("RGB")
    if fit_w and fit_h:
        return _cover(img, fit_w, fit_h)
    if fit:
        return _cover(img, fit, fit)
    return img


def save_processed(raw: bytes, dest: Path, asset: dict) -> None:
    from io import BytesIO

    transparent = bool(asset.get("transparent", False))
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / f"{asset['id']}.png").write_bytes(raw)
    img = Image.open(BytesIO(raw))
    processed = trim_and_fit(
        img,
        asset.get("fit"),
        asset.get("fit_w"),
        asset.get("fit_h"),
        transparent=transparent,
    )
    dest.parent.mkdir(parents=True, exist_ok=True)
    processed.save(dest, "PNG")
    print(f"  -> {dest.relative_to(ROOT)} ({processed.size[0]}x{processed.size[1]})")


def append_manifest(row: dict) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    new = not MANIFEST.exists()
    with MANIFEST.open("a", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["id", "dest", "model", "size", "quality", "status", "note"])
        if new:
            w.writeheader()
        w.writerow(row)


def expand_hedgehog_copies() -> None:
    """Fill frames 4-8 and skins 4-8 by cycling generated frames."""
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
    print("hedgehog frame/skin copies done")


def fill_extra_decor() -> None:
    """Duplicate key decor/clouds into unused slots that other code may load."""
    pairs = [
        ("decor1/decor1er_0.png", "decor1/decor1er_2.png"),
        ("decor1/decor1er_1.png", "decor1/decor1er_3.png"),
        ("decor2/decor2nd_0.png", "decor2/decor2nd_1.png"),
        ("decor2/decor2nd_0.png", "decor2/decor2nd_2.png"),
        ("decor2/decor2nd_0.png", "decor2/decor2nd_3.png"),
        ("nuages/haut_0.png", "nuages/haut_1.png"),
        ("nuages/haut_0.png", "nuages/haut_2.png"),
        ("nuages/moyen_0.png", "nuages/moyen_1.png"),
        ("nuages/bas_0.png", "nuages/bas_1.png"),
        ("nuages/bas_0.png", "nuages/bas_2.png"),
        ("nuages/bas_0.png", "nuages/bas_3.png"),
        ("nuages/bas_0.png", "nuages/bas_4.png"),
        ("snow/snow_flake0.png", "snow/snow_flake1.png"),
        ("snow/snow_flake0.png", "snow/snow_flake2.png"),
        ("menu/2emeplan.png", "decor2/2emeplan.png"),
    ]
    tex = ROOT / "godot/assets/textures"
    for a, b in pairs:
        src, dst = tex / a, tex / b
        if src.exists():
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)


def run(ids: list[str] | None, quality: str, model: str, skip_existing: bool) -> None:
    client = OpenAI(api_key=load_key())
    data = json.loads((Path(__file__).parent / "prompts.json").read_text(encoding="utf-8"))
    prefix = data["style_prefix"]
    assets = list(data["assets"])
    for a in data["alphabet"]:
        assets.append(
            {
                "id": a["id"],
                "dest": a["dest"],
                "transparent": True,
                "size": "1024x1024",
                "fit_w": 48,
                "fit_h": 80,
                "prompt": data["alphabet_prompt"].format(char=a["char"]),
            }
        )
    if ids:
        want = set(ids)
        assets = [a for a in assets if a["id"] in want]
    for asset in assets:
        dest = ROOT / asset["dest"]
        if skip_existing and dest.exists() and dest.stat().st_size > 500:
            print(f"skip {asset['id']}")
            continue
        prompt = f"{prefix} {asset['prompt']}"
        print(f"gen {asset['id']} ...")
        try:
            raw = gen_one(
                client,
                prompt=prompt,
                size=asset.get("size", "1024x1024"),
                transparent=bool(asset.get("transparent", False)),
                quality=quality,
                model=model,
            )
            save_processed(raw, dest, asset)
            append_manifest(
                {
                    "id": asset["id"],
                    "dest": asset["dest"],
                    "model": model,
                    "size": asset.get("size", ""),
                    "quality": quality,
                    "status": "ok",
                    "note": "",
                }
            )
        except Exception as e:
            print(f"FAIL {asset['id']}: {e}")
            append_manifest(
                {
                    "id": asset["id"],
                    "dest": asset["dest"],
                    "model": model,
                    "size": asset.get("size", ""),
                    "quality": quality,
                    "status": "fail",
                    "note": str(e)[:200],
                }
            )
            time.sleep(2)
        time.sleep(0.4)
    expand_hedgehog_copies()
    fill_extra_decor()


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--ids", nargs="*", help="Optional asset ids")
    p.add_argument("--quality", default="medium")
    p.add_argument("--model", default="gpt-image-1")
    p.add_argument("--force", action="store_true")
    p.add_argument("--copies-only", action="store_true")
    args = p.parse_args()
    if args.copies_only:
        expand_hedgehog_copies()
        fill_extra_decor()
        return
    run(args.ids, args.quality, args.model, skip_existing=not args.force)


if __name__ == "__main__":
    main()
