# Heriswap (Godot rewrite)

Match-3 leaf game rewritten in **Godot 4.4** (GDScript).

The original C++ / [sac](https://github.com/SoupeauCaillou/sac) implementation remains in this repository as **reference** (`sources/`, `android/`, `assets/`, `datas/`). The playable product is under [`godot/`](godot/).

## Requirements

- Godot **4.4+**
- Optional: Android SDK/NDK for APK export

## Run

```bash
cd godot
godot --path .
```

## Tests

```bash
cd godot
godot --headless --path . -s res://test/test_grid.gd --quit-after 15
```

Expect `TEST_GRID_OK`.

## Features

- 3 modes × 3 difficulties with branch leaves, hedgehog progress/hint, decor + clouds
- Match-3 loop with difficulty timings, level-up FX (snow/desaturate), Elite popup, Go100 squall
- Multi-track jukebox + stress ramp
- Scores/options JSON, mid-game resume, 20 local achievements
- i18n CSV (15 locales) + locale picker
- `PlatformServices`: F-Droid-safe (no Play rate/IAP); Play hooks via optional Android singletons

## Export

Presets in `godot/export_presets.cfg`:

| Preset | Notes |
|--------|--------|
| Linux / Windows | desktop |
| Android Play | `net.damsy.soupeaucaillou.heriswap2` |
| Android F-Droid | same package + `fdroid` feature (hides Play Store rate / billing) |

New Android package (clean rewrite), not an update of `net.damsy.soupeaucaillou.heriswap`.

Enable Play adapters with `HERISWAP_ENABLE_PLAY=1` or by installing Godot Play/Billing plugins (detected via `Engine.has_singleton`).

## Legacy C++ build

<details>
<summary>Original C++ / sac build (reference)</summary>

```bash
git submodule update --init --recursive
./sac/tools/build/build-all.sh --target linux n
```

</details>

## License

GPL-3 for code (see [LICENSE](LICENSE)). Artwork: CC-by (see LICENSE).
