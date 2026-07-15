# Heriswap (Godot rewrite)

Match-3 leaf game rewritten in **Godot 4.4** (GDScript).

Legacy C++ / sac code remains as **reference**. Product lives in [`godot/`](godot/).

## Run

```bash
cd godot && godot --path .
```

## Play controls

Drag adjacent leaves on the playfield (below the HUD) to swap. Invalid swaps vibrate on mobile.

## Tests

```bash
cd godot && godot --headless --path . -s res://test/test_grid.gd --quit-after 15
```

## Features

- Match-3 with difficulty timings, branch leaves, hedgehog hint, decor
- Level-up FX (snow + desaturate shader), Go100 physical squall
- Multi-track jukebox + stress ramp
- Menus styled with original art (`fond_bouton`, backdrops)
- Scores JSON, mid-game resume, 20 local achievements
- 15 locales + locale picker
- **Offline platform**: no Google Play Games / IAP plugins; F-Droid-friendly (`PlatformServices`)

## Package

`net.damsy.soupeaucaillou.heriswap2` (new listing).

## License

GPL-3 / CC-by - see [LICENSE](LICENSE).
