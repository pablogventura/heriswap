# AGENTS.md - Heriswap

## Stack

- Godot 4.4 in [`godot/`](godot/); legacy C++/sac is reference only
- Package: `net.damsy.soupeaucaillou.heriswap2`
- Offline `PlatformServices` (no Play/Billing plugins)

## Commands

| Action | Command |
|--------|---------|
| Run | `cd godot && godot --path .` |
| Tests | `cd godot && godot --headless --path . -s res://test/test_grid.gd --quit-after 15` |

## Match input

Gameplay clicks go to `PlayfieldInput` (`mouse_filter=STOP`). Backdrop `ColorRect`s use `IGNORE`. Swap supports drag motion between orthogonal neighbors.

## Do not

- Enable Google plugins unless explicitly requested
- Load sac `.entity`/`.atlas` at runtime
- Block playfield with fullscreen STOP Controls
