# AGENTS.md - Heriswap

## Stack

- Godot 4.4 in [`godot/`](godot/); legacy C++/sac is reference only
- Package: `net.damsy.soupeaucaillou.heriswap2`
- Offline `PlatformServices` (no Play/Billing plugins)
- Design canvas 800×1280, stretch `canvas_items` + `keep`

## Commands

| Action | Command |
|--------|---------|
| Run | `cd godot && godot --path .` |
| Tests | `cd godot && godot --headless --path . -s res://test/test_grid.gd --quit-after 15` |

## Match input / morph

Gameplay clicks go to `PlayfieldInput` (`mouse_filter=STOP`). Backdrop `ColorRect`s use `IGNORE`. Swap supports drag between orthogonal neighbors.

Morph phases animate sprites first (`_animating` / `_swap_locked`), then commit `GridModel` on tween finish (swap → delete → fall waves → spawn grow).

## UI

- `UiTheme` / `UiLayout`: FreeMono LabelSettings, `fond_bouton` hover/press, fixed Control coords
- `AlphabetDigits`: bitmap glyphs from `assets/textures/alphabet/` for scores; FreeMono fallback

## Do not

- Enable Google plugins unless explicitly requested
- Load sac `.entity`/`.atlas` at runtime
- Block playfield with fullscreen STOP Controls
- Treat device APK smoke as required for desktop polish work
