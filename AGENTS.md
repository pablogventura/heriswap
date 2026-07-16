# AGENTS.md - ScrapSwap

## Stack

- Godot 4.4 in [`godot/`](godot/); legacy C++/sac is reference only
- Package: `net.damsy.soupeaucaillou.heriswap2` (display name ScrapSwap; package id not migrated)
- Offline `PlatformServices` (no Play/Billing plugins)
- Design canvas 800×1280, stretch `canvas_items` + `keep`
- Locales in build: `en`, `es`, `pt_BR`, `fr`, `de` (system locale if matched, else `en`)

## Commands

| Action | Command |
|--------|---------|
| Run | `cd godot && godot --path .` |
| Tests (all) | `cd godot && godot --headless --path . -s res://test/test_all.gd --quit-after 30` |
| Tests (grid) | `cd godot && godot --headless --path . -s res://test/test_grid.gd --quit-after 15` |
| Validate levels | `cd godot && godot --headless --path . -s res://test/validate_levels.gd --quit-after 15` |

## Match input / morph

Gameplay clicks go to `PlayfieldInput` (`mouse_filter=STOP`). Backdrop `ColorRect`s use `IGNORE`. Swap supports drag between orthogonal neighbors.

Morph phases animate sprites first (`_animating` / `_swap_locked`), then commit `GridModel` on tween finish (swap → delete → fall waves → spawn grow).

## Match juice

`JuiceFx` owns paper-craft match feedback: layered `CPUParticles2D` bursts (scraps/confetti), shockwave rings, explode arcs (occasional fake flip), float text, combo banners, grid shake/zoom punch, `leaf_glow` / `leaf_pop` / `screen_flash` shaders, drag trail. Paper morph: `fall_flutter` on falls, `paper_spin_flutter` + occasional `paper_flip` on spawn (always on new specials), `land_shadow_flash` with land squash. `MatchDecor` ambient layer drift + `parallax_punch` from `camera_punch` (scaled by `juice_scale(combo_chain)`). Clear is two-phase: **telegraph** (yarn threads / tape sweep / foil rays / wrap ring / plane trails) then destroy morph - every delete wave including cascades. Wired from `match_root.gd` on swap/delete/fall/spawn/level-up/squall. Specials use `special_created`. Do not leave glow materials on sprites during level-up desaturate (`juice.level_locked`). `reduce_motion` skips telegraph, flutter, flip, land shadow flash, and decor parallax punch. Art direction: chaotic primary-school paper collages (see `tools/paper_gen/`).

## ScrapSwap modes

- **Quest** (default corkboard map): `LevelCatalog` JSON, stickers / score / ingredients / orders, craft tray, sugar-crush, Daily Desk, Scrap Codex.
- **Arcade**: Normal / Tiles / 100s + Zen.
- Specials: rayado / paquete / confetti / avioncito (`MatchSpecials`); blockers on `GridModel`.

## UI

- `UiTheme` / `UiLayout`: **Fredoka** LabelSettings (FreeMono fallback), `fond_bouton` hover/press, fixed Control coords, button scale punch
- `AlphabetDigits`: bitmap glyphs from `assets/textures/alphabet/` for scores; Fredoka fallback; pulse on score change

## Do not

- Enable Google plugins unless explicitly requested
- Load sac `.entity`/`.atlas` at runtime
- Block playfield with fullscreen STOP Controls
- Treat device APK smoke as required for desktop polish work
- Add ads, IAPs, or paywalls
