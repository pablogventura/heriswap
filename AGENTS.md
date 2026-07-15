# AGENTS.md - Heriswap

Minimal guide for coding agents. Prefer [README.md](README.md) for run/export notes.

## Stack

- **Product:** Godot **4.4** under [`godot/`](godot/)
- **Legacy reference:** C++ + sac (`sources/`, `android/`, `datas/`, `assets/`)
- Android package: `net.damsy.soupeaucaillou.heriswap2`
- Persistencia: JSON en `user://` (`SaveService`)
- Offline-first: `PlatformServices` (F-Droid feature disables Play rate/IAP)

## Commands

| Action | Command |
|--------|---------|
| Run | `cd godot && godot --path .` |
| Tests | `cd godot && godot --headless --path . -s res://test/test_grid.gd --quit-after 15` |
| Legacy C++ | `./sac/tools/build/build-all.sh` (needs `sac` submodule) |

## Layout

```
godot/
  scenes/ scripts/{grid,modes,match,flow,save,platform,ui,audio,achievements}
  assets/textures/{feuilles,decor1,decor2,nuages,snow,menu,help,logo}
  localization/heriswap.csv   # 15 locales
  test/test_grid.gd
```

## Conventions

- Autoloads: `GameFlow`, `SaveService`, `PlatformServices`, `AudioBus`, `LocaleService`, `Achievements`, `RunSnapshot`
- Match visuals: `MatchDecor`, `BranchLeavesView`, `HedgehogActor`, `TimingConfig`
- Modes call `bind_branch`; achievements hooks from `MatchRoot`
- Do not call Google APIs outside `PlatformServices`
- Conventional Commits; English identifiers

## Do not

- Load sac `.entity` / `.atlas` / DDS at runtime
- Reuse old applicationId
- Delete legacy C++ without explicit decision
- Use SQLite for scores
