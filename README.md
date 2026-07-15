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

## Export

Presets in `godot/export_presets.cfg`:

| Preset | Package |
|--------|---------|
| Linux / Windows | desktop binaries |
| Android Play | `net.damsy.soupeaucaillou.heriswap2` |
| Android F-Droid | same package + `fdroid` feature (no Google services) |

This is a **new** Android package (clean rewrite), not an update of `net.damsy.soupeaucaillou.heriswap`.

## Features

- 3 modes × 3 difficulties (Score race, Time attack, 100 seconds)
- Match-3 grid with swap, delete, fall, spawn, no-move reset
- Menus, help, pause, high scores (JSON), mid-game resume
- Local achievements + `PlatformServices` stubs (Play Games / IAP offline-first)
- i18n CSV (`en`, `es`, `fr`, `de`)

## Legacy C++ build

See historical instructions below only if you need the sac engine build. It is **not** required for the Godot game.

<details>
<summary>Original C++ / sac build (reference)</summary>

Prerequisites: `git`, `cmake`, `g++`; Android SDK/NDK for APK.

```bash
git submodule update --init --recursive
./sac/tools/build/build-all.sh --target linux n
```

</details>

## License

GPL-3 for code (see [LICENSE](LICENSE)). Artwork: CC-by (see LICENSE). Engine exceptions for sac remain under `sac/LICENSE` when the submodule is present.

## Authors

Soupe au Caillou - original game. Godot port lives in `godot/`.
