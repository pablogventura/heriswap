# ScrapSwap

Paper craft match-3 (ScrapSwap) rewritten in **Godot 4.4** (GDScript).

Legacy C++ / sac code remains as **reference**. Product lives in [`godot/`](godot/).

## Run

```bash
cd godot && godot --path .
```

Viewport design canvas: **800×1280**, stretch `canvas_items` + `keep` (window override 400×640 for desktop). Leaf/alphabet textures use nearest filtering for hi-dpi crispness.

## Play controls

Drag adjacent leaves on the playfield (below the HUD) to swap. Invalid swaps vibrate on mobile. Swap / delete / fall / spawn morph the view first, then commit the grid model.

## Features

- **Quest** corkboard (default): stickers / score / ingredients / orders, craft tray boosters, sugar-crush, Daily Desk, Scrap Codex
- **Arcade** + Zen: classic Normal / Tiles / 100s plus endless desk
- Paper specials (rayado, paquete, confetti, avioncito) and blockers (tape, scrap, glue, …)
- Match-3 morphs: branch leaves, decor, hint button
- **Match juice** (`JuiceFx`): bursts, shockwaves, combo banners, float score, camera punch, shaders, drag trail
- Free play: no ads, no purchases; GPL-3.0
- Locales in game: en, es, pt_BR, fr, de (system default when matched)
- Scores JSON, mid-game resume, local achievements, save export
- Offline platform (`PlatformServices`); headless tests + level validator

## Tests

```bash
cd godot && godot --headless --path . -s res://test/test_all.gd --quit-after 30
cd godot && godot --headless --path . -s res://test/test_grid.gd --quit-after 15
cd godot && godot --headless --path . -s res://test/validate_levels.gd --quit-after 15
```

## Desktop checklist (visual polish)

- [ ] Logo → MainMenu layout and SAC about shortcut
- [ ] ModeMenu modes/diffs/scores + alphabet best score digits
- [ ] Countdown curtain + numbers
- [ ] Match: swap lerp, delete fade, fall, spawn grow
- [ ] Juice: bursts, explode arcs, shockwave, trail glow, shake/zoom
- [ ] Juice: anticipation swap, land squash, drop-in spawn, ProgressBar flash
- [ ] Level-up text/snow/confetti; Go100 squall burst
- [ ] Help backgrounds cycle with pages
- [ ] Pause panel buttons readable / micro punch

## Package

`net.damsy.soupeaucaillou.heriswap2` (new listing). Soft export targets desktop + Android; APK device verification is not part of the offline polish pass.

## License

GPL-3 / CC-by - see [LICENSE](LICENSE).
