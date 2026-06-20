# Pixel Valley

[![Play on itch.io](https://img.shields.io/badge/Play_on-itch.io-red?style=for-the-badge)](https://fissionwizzard.itch.io/pixel-valley)
[![Feedback](https://img.shields.io/badge/Give-Feedback-green?style=for-the-badge)](https://docs.google.com/forms/d/e/1FAIpQLSfSQfVvR3tb8YQT35z_nKu22EymHAmQoNdFdEDBGPzVtnijzw/viewform)

Pixel Valley is a solo-developed retro fantasy JRPG built in Godot 4. Choose a hero, protect your village, complete quests, unlock new regions, and battle escalating threats across the valley.

This project is also a long-term learning project focused on modular, data-driven RPG architecture with GDScript and Godot Resources.

---

## Current Status

Pixel Valley is playable and actively in development. The current project version is `0.1.2`.

Implemented systems include hero creation, a village hub, explorable combat zones, turn-based battles, a main quest chain, shops, an inn, inventory/equipment management, save slots, HUD panels, rewards, loot drops, and placeholder audio/visual content.

The game is still pre-release. Current work is focused on combat-area polish, balancing, side content, audiovisual polish, and tightening the player flow.

---

## Game Overview

Players choose one of three hero classes:

- Knight
- Assassin
- Princess

Each class has its own stats, weapon pool, equipment progression, and combat style. The main progression moves from Pixel Valley into the Goblin Forest, Orc War Camp, and Ogre Cave, ending with the Ogre King.

---

## Features

### Combat

- Turn-based battle flow driven by `BattleManager`
- Energy and cooldown-based weapon abilities
- Monster AI using conditional abilities
- Buffs, debuffs, active effects, meditation, potions, loot, gold, and experience rewards
- Battle UI with animated hero and monster presentation

### Progression

- Leveling with skill point gains
- Stats panel with temporary skill allocation and confirmation
- Class-specific common, rare, and legendary weapons
- Random weapon rewards with duplicate fallback gold
- Weapon stash and equip flow through the inventory panel

### Quests

- Data-driven main quest chain defined in `resources/quests/`
- 10 current quest resources
- Slay objectives with location-specific tracking
- Quest turn-ins with gold, experience, item, and weapon rewards
- Quest-based location unlocks
- Final quest path into the victory screen

### World

- Pixel Valley / village hub
- Goblin Forest
- Orc War Camp
- Ogre Cave
- Building exteriors and interiors for the inn, potion shop, and weapon shop
- Trigger zones, spawn points, and persistent defeated-spawner state

### Village Systems

- Inn: rest/recovery window
- Potion shop: purchasable consumables
- Weapon shop: class-appropriate common weapons
- Quest screen and quest HUD panel

### HUD and UI

- Persistent world HUD owned by `ScreenManager`
- Tabbed in-game HUD with Stats, Inventory, Quests, and System panels
- New game, load, options, shop, reward, death, battle, quest, and victory screens/windows
- Keyboard and controller input bindings in `project.godot`

### Persistence

- Multiple save slots
- JSON save files under `user://saves`
- Saved hero stats, inventory, equipped weapon, active effects, village/shop state, quests, world unlocks, defeated spawners, and player location
- Resource visual data is reapplied through loaders instead of being serialized directly

### Audio

- Background music through `AudioManager`
- SFX support for combat/rewards using spawn-and-free audio players
- Separate Music, SFX, and UI buses

---

## Technical Architecture

Pixel Valley uses a data-driven Godot architecture:

- `autoload/` contains global managers such as `GameState`, `ScreenManager`, `SaveManager`, `WorldManager`, `AudioManager`, `ItemLoader`, `WeaponDatabase`, `MonsterLoader`, and `HeroLoader`.
- `resources/` contains game data for heroes, monsters, abilities, weapons, potions, quests, rewards, UI themes, and sprite frames.
- `scenes/` contains reusable world, UI, HUD, component, and screen scenes.
- `scripts/` contains gameplay, world, UI, data, and system logic.

Core patterns:

- `BaseLocation` and `BaseCombatLocation` power world scenes.
- `TriggerZone`, `Building`, `InteractArea`, and `SpawnPoint` handle world interactions.
- `ScreenManager` owns scene transitions and keeps `WorldHUD` persistent across world screens.
- `BattleManager` emits signals consumed by `BattleScreen` and battle UI components.
- `QuestManager` is a `Resource` owned by `GameState`, not an autoload.
- Shops and rewards use item IDs resolved through `ItemLoader` and `WeaponDatabase`.

---

## Getting Started

1. Install Godot 4.6 or newer.
2. Clone this repository.
3. Open `project.godot` in Godot.
4. Press **F5** to run the game.

The Godot Git plugin is included for editor integration, but no external setup is required to run the project.

---

## Project Structure

```text
addons/         Godot editor plugins
assets/         Character, world, battle, item, and UI art
audio/          Background music, SFX, and bus layout
autoload/       Global managers and loaders
exports/        Export output/configuration
resources/      Data-driven game content (.tres)
scenes/         World scenes, UI screens, HUDs, windows, and components
scripts/        GDScript gameplay, systems, data, world, and UI logic
```

---

## Development Roadmap

### In Progress

- Combat area level design polish
- Boss and zone difficulty balancing
- Shop, inventory, and HUD polish
- Audio and art pass over placeholder content
- Branding and final game name decision

### Planned

- Side quests and additional quest variety
- More combat polish and encounter tuning
- Expanded audiovisual feedback
- Additional balancing passes using the project workbook
- Possible random encounters
- Publishing polish for itch.io and the project website

---

## Play the Latest Build

Play Pixel Valley on itch.io:

https://fissionwizzard.itch.io/pixel-valley

---

## Credits

Developed by Nick Avtges using Godot Engine.

---

## License

No top-level license file is currently included in this repository.
