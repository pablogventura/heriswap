# AGENTS.md - Heriswap

Minimal guide for coding agents. Prefer [README.md](README.md) for human-facing run/export notes.

## Stack

- **Product:** Godot **4.4** GDScript under [`godot/`](godot/)
- **Legacy reference:** C++ + sac (`sources/`, `android/`, `datas/`, `assets/`) - do not treat as the shipping game
- Android package (new): `net.damsy.soupeaucaillou.heriswap2`
- Persistencia: JSON versionado en `user://` (`SaveService`)
- Offline-first: `PlatformServices` stubs; no Google required for gameplay

## Commands

| Action | Command |
|--------|---------|
| Run game | `cd godot && godot --path .` |
| Grid tests | `cd godot && godot --headless --path . -s res://test/test_grid.gd --quit-after 15` |
| Install / lint / typecheck / migrate | not detected |
| Legacy C++ build | `./sac/tools/build/build-all.sh` (needs `sac` submodule) |

## Layout

```
godot/
  project.godot          # 800x1280 portrait, canvas_items + keep
  scenes/                # menus, match, overlays
  scripts/               # grid, modes, flow, save, platform, ui
  assets/                # PNG feuilles, OGG, shaders
  localization/          # heriswap.csv
  test/test_grid.gd      # headless unit tests
  export_presets.cfg
sources/ android/ …      # legacy C++/sac (reference only)
```

## Conventions

- English identifiers and commit messages (Conventional Commits)
- Autoloads: `GameFlow`, `SaveService`, `PlatformServices`, `AudioBus`, `LocaleService`, `Achievements`, `RunSnapshot`
- Modes: `NormalMode`, `TilesAttackMode`, `Go100SecondsMode` via `GameModeBase.create`
- Grid rules live in `GridModel` (pure data); view/input in `MatchRoot`
- Do not call Play/IAP outside `PlatformServices`
- Do not use SQLite for scores

## Tests

- Primary suite: `godot/test/test_grid.gd` (match, fall, swap, mode scoring stubs)
- Success: prints `TEST_GRID_OK`

## Do not

- Load sac `.entity` / `.atlas` / DDS-PKM at runtime in Godot
- Reuse old applicationId `net.damsy.soupeaucaillou.heriswap`
- Delete legacy C++/sac without an explicit Phase-8 parity decision
- Invent npm/pip workflows for this project
- Commit keystores or `local.properties`
