# Pixel Valley — Project Context

## Overview
**Pixel Valley** (working title, formerly "VillageDefense") is a retro pixel-art JRPG built in **Godot 4** with **GDScript**, developed solo and published on itch.io. It features a village hub world, three hero classes (Knight, Assassin, Princess), turn-based combat, and an escalating enemy progression: Goblins → Orcs → Ogres → Ogre King. Key locations: Pixel Valley (village hub), Goblin Forest, Orc War Camp, Ogre Cave, tied together by a quest system.

The final game name isn't locked — leaning toward valley-imagery, with **Cresthollow** and **Ashenvale** as top candidates.

## Tools & Resources
- **Engine**: Godot 4 (GDScript)
- **Version control**: GitHub — `navtges3/village-defense`
- **Publishing**: itch.io (Pixel Valley listing), GitHub Pages (`navtges3.github.io/village-defense-site/`)
- **Balancing reference**: Excel workbook `VillageDefense_Balancing.xlsx` (monster scaling, hero progression by class, balance checks, weapons)
- **Key autoloads**: `GameState`, `ScreenManager`, `SaveManager`, `WorldManager`, `AudioManager`, `ItemLoader`, `WeaponDatabase`, `MonsterLoader`, `HeroLoader`

## Core Architecture
- `BaseLocation` → `BaseCombatLocation` inheritance for world scenes
- `TriggerZone` / `Building` for world interaction; `InteractArea` (Area2D) handles player interaction via E key, following `TriggerZone` conventions
- `CanvasLayer`-based HUD: `WorldHUD` (owned by `ScreenManager`, persistent across world screens) and `GameHUD` (tabbed overlay: Stats, Inventory, Quests, System panels)
- Popup windows (`InnWindow`, `ShopWindow`) are `Control`-based, wrapped in `CanvasLayer` (layer 10) to avoid camera zoom affecting their size/position
- Signal-driven: `BattleManager` emits signals delegated to `BattleScreen`; HUD components connect to `GameState` signals rather than polling, except `Hero` (no signals exposed), which uses dirty-check `_process`
- **Save system**: multiple JSON files (`hero`, `world_state`, `zone_state`, `meta`) managed by `SaveManager`; static visual fields are stripped before saving and reapplied via `HeroLoader.apply_visual()` on load
- **Audio**: `.wav` SFX at `res://assets/audio/sfx/`, spawn-and-free pattern in `AudioManager`

## Godot 4 / GDScript Best Practices (apply to all code in this repo)
- **Static typing everywhere.** Use `var health: int`, `func take_damage(amount: int) -> void`, etc. Catches errors at edit time and matches existing code style.
- **Cache node references with `@onready`**, never call `get_node()` / `$Node` repeatedly inside `_process()`, `_physics_process()`, or other hot paths.
- **Signals over direct references.** Decouple nodes/scenes with signals rather than reaching into other nodes directly — this is the established pattern throughout the project (see `BattleManager`/`BattleScreen`, `GameState` signals).
- **Resources are data-only.** `Resource`-derived classes (e.g. `WeaponData`, `QuestManager`) should hold exported data and light helper methods, not heavy game logic.
- **Autoloads sparingly.** Only truly global, always-needed systems belong as autoloads (see the existing list under Key Autoloads above) — don't add new ones casually; prefer passing data through the existing `screen_data` / signal pipelines.
- **Object pooling for frequently spawned nodes** (e.g. projectiles, VFX, hit numbers) to avoid GC hitches — avoid `instantiate()`/`queue_free()` churn in hot loops.
- **Don't fight the scene tree.** Favor composition (child nodes/components like `HitboxComponent`, `InteractArea`) over monolithic scripts.
- **Disable processing when off-screen or inactive** (`set_process(false)`, `set_physics_process(false)`) rather than guarding every frame with an `if`.
- **Respect this project's specific gotchas** (see Key Learnings below) — these aren't generic Godot trivia, they're things that have already broken once in this codebase: Y-sort propagation, node init order before `add_child()`, animation loop flags, `queue_free()` vs `free()` timing, and signal timing for late-initialized state.
- **Never rename or move `.tres`/`.tscn`-referenced assets via shell commands** (`mv`, `git mv`, etc.). These files contain UID-based `ext_resource` paths that only Godot's FileSystem dock rewrites correctly — a shell rename leaves broken references that may not surface until runtime.

## Current Systems In Progress
- **Stats panel**: skill point allocation moved into `stats_panel.gd` directly (Training Grounds scene removed), using `_temp_allocations` + `_available_points`, green label coloring, conditional `ConfirmButton`
- **Building interiors**: Inn, weapon shop, potion shop implemented as `BaseLocation` scenes
- **Shop system**: generic `ShopScreen` with a `ShopType` enum; weapon shop defaults to class-appropriate common-rarity weapons from `WeaponDatabase.CLASS_WEAPON_TABLE`; shop data flows `TriggerZone → player.gd → ScreenManager → ShopScreen.setup()` via `screen_data` export
- **Weapon equipping**: Equip button in `inventory_panel.gd`, emits `weapon_equipped` signal, calls `refresh()` atomically
- **Repo housekeeping**: temp files/build artifacts cleared, audio consolidated, weapon sprites renamed via Godot's FileSystem dock, quest filenames zero-padded, snake_case enforced throughout

## Key Learnings & Gotchas (important for any contributor/agent)
- **Y-sort** must be enabled at *every* level of the node hierarchy, not just the container, or depth sorting breaks
- **Node init order**: always set data on a node *before* `add_child()` — `_ready()` fires at add time (critical for spawners, VFX, weapon/visual setup)
- **Asset renames**: must be done via Godot's FileSystem dock, not OS-level/`git mv` — the editor rewrites `ext_resource` paths and regenerates `.import` sidecars; manual renames break references
- **Animation looping**: only `idle`/`walk` should loop; `attack`/`hurt`/`block`/`death` must not loop, or `animation_finished` won't fire
- **`queue_free()` vs `free()`**: `queue_free()` leaves a departing scene in the tree long enough to contaminate group queries (e.g. `get_nodes_in_group("trigger_zone")`); use `free()` before adding a new scene
- **Signal timing**: HUD elements depending on late-initialized state (e.g. `QuestManager` on `GameState`) need a dedicated ready signal fired post-init, not just `_ready()`
- **`QuestManager`** is a Resource owned by `GameState`, not an autoload — created on `new_game()`/`load_game()`, null on `reset_state()`
- **Weapon sprites**: `WeaponAnchor` hand positions/rotations are authored right-facing only; `anchor.scale.x = -1` mirrors for left-facing
- **VFX reparenting**: trail/VFX nodes must be children of a stable reference frame (e.g. `Visual`), not the moving anchor, or `to_local()` returns a constant
- **`ItemLoader` identity**: shop-purchased items use `duplicate()`, breaking reference-equality — name-based fallback in `get_item_id()` handles this, but canonical registry instances are preferred
- **Balancing**: damage comes from weapon abilities, not the hero's `attack` stat directly

## Working Patterns / Preferences
- Confirm scope and affected files before writing code; targeted, minimal changes over broad rewrites
- Iterative, one-focus-at-a-time; confirm a fix works before moving on
- New systems mirror established patterns (e.g. `HeroLoader` mirrors `MonsterLoader`; `AudioManager.play_sfx_by_id()` mirrors `play_music_by_id()`)
- Roadmap tracked via GitHub milestones/issues; playtest feedback from friends via Discord gets converted into issues
- Placeholder-first: systems built with placeholder art/audio, real assets swapped in later

## On the Horizon
- Final game name decision (Cresthollow / Ashenvale leading)
- Combat area level design polish
- Side quests
- Combat balancing (boss difficulty, zone-locked monster level brackets)
- Audio/art pass (currently placeholder)
- Further shop/inventory polish
- Branding finalization
- Random encounters (parked, possible future feature)
