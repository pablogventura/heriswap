# Heriswap (Godot rewrite)

Match-3 leaf game rewritten in **Godot 4.4** (GDScript).

Legacy C++ / sac code remains as **reference**. Product lives in [`godot/`](godot/).

## Run

```bash
cd godot && godot --path .
```

Viewport design canvas: **800×1280**, stretch `canvas_items` + `keep` (window override 400×640 for desktop). Leaf/alphabet textures use nearest filtering for hi-dpi crispness.

## Play controls

Drag adjacent leaves on the playfield (below the HUD) to swap. Invalid swaps vibrate on mobile. Swap / delete / fall / spawn morph the view first, then commit the grid model.

## Tests

```bash
cd godot && godot --headless --path . -s res://test/test_grid.gd --quit-after 15
```

## Features

- Match-3 with difficulty timings, ADSR-like morph tweens, branch leaves, hedgehog hint, decor
- Level-up FX (snow flakes + desaturate), denser Go100 physical squall
- Multi-track jukebox + stress ramp
- Menus on fixed 800×1280 Control layout with original art (`fond_bouton`, layered plans, SAC)
- FreeMono theme + selective alphabet bitmap digits on HUD / scores
- Scores JSON, mid-game resume, 20 local achievements (SuccessManager thresholds)
- Help pages with `bg_help_*` backgrounds
- 15 locales + locale picker
- **Offline platform**: no Google Play Games / IAP plugins; F-Droid-friendly (`PlatformServices`)

## Desktop checklist (visual polish)

- [ ] Logo → MainMenu layout and SAC about shortcut
- [ ] ModeMenu modes/diffs/scores + alphabet best score digits
- [ ] Countdown curtain + numbers
- [ ] Match: swap lerp, delete fade, fall, spawn grow
- [ ] Level-up text/snow; Go100 squall burst
- [ ] Help backgrounds cycle with pages
- [ ] Pause panel buttons readable

## Package

`net.damsy.soupeaucaillou.heriswap2` (new listing). Soft export targets desktop + Android; APK device verification is not part of the offline polish pass.

## License

GPL-3 / CC-by - see [LICENSE](LICENSE).
