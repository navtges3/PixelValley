# Village Defense

[![Download](https://img.shields.io/badge/⬇️_Download-Windows-blue?style=for-the-badge)](https://drive.google.com/uc?export=download&amp;id=1pqgvn15C7bhNAVS57PRTVXzRTVNdZSzz)
[![Feedback](https://img.shields.io/badge/📝_Give-Feedback-green?style=for-the-badge)](https://docs.google.com/forms/d/e/1FAIpQLSfSQfVvR3tb8YQT35z_nKu22EymHAmQoNdFdEDBGPzVtnijzw/viewform?usp=sharing&ouid=110993499414547181758)

A solo-developed fantasy RPG built with Godot 4.6. You pick a hero, take on quests, fight monsters, and try to keep your village standing.

It's a personal project I've been building to learn Godot and GDScript — the systems are designed to be modular and data-driven so they're easy to extend as the game grows.

---

## Overview

Village Defense is a single-player turn-based RPG. You choose a hero class (Knight, Assassin, or Princess), gear up at the village shop, take quests from the quest board, and head out to fight escalating waves of enemies. Progression comes through new weapons, skill point allocation, and a quest chain that unlocks as you complete objectives.

Most gameplay content — monsters, abilities, weapons, quests, effects — is defined in Godot `Resource` files rather than hard-coded, which makes it easy to add new content without touching the core logic.

---

## Features

- **Turn-based combat** with abilities, energy costs, and cooldowns
- **Three hero classes** — Knight, Assassin, and Princess — each with their own weapon pool and playstyle
- **Conditional monster AI** — enemies choose abilities based on battle state (health thresholds, energy levels, etc.)
- **Buff/debuff system** with stat modifiers that apply and expire cleanly over turns
- **Village hub** with a shop, inn, and quest board
- **Quest chain** with 15+ quests, structured rewards (gold, XP, class-specific weapons), and unlock progression
- **Save/load system** with multiple save slots and persistent game state
- **Overworld map** *(in progress)* — top-down exploration with tile-based location triggers

---

## Getting Started

1. Download and install [Godot 4.6](https://godotengine.org/download)
2. Clone or download this repository
3. Open Godot, click **Import**, and select the `project.godot` file
4. Hit **Run** (F5) to play from the main menu

No plugins or external dependencies required.

---

## Project Structure

```
autoload/       # Singletons: GameState, SaveManager, ScreenManager, AudioManager, etc.
scripts/
  characters/   # Hero, Monster, Combatant, Inventory, StatBlock
  data/         # Ability, Attack, Effect, ActiveEffect, Weapon, Potion, Item, Quest, QuestReward, QuestObjective
  systems/      # BattleManager, QuestManager, ShopManager
  ui/           # Screen and component scripts
  world/        # Player, overworld scripts
resources/      # All game data as .tres files (heroes, monsters, weapons, quests, abilities)
scenes/         # Godot scenes for all screens, components, and the overworld
assets/         # Sprites and UI images
audio/          # Background music
```

---

## Roadmap

- Overworld map with explorable locations
- Status effects (burn, stun, regen)
- Expanded monster roster
- Weapon upgrades and crafting
- Branching and optional quests
- Visual polish and animations

---

## Credits

Developed by **Nick** using the [Godot Engine](https://godotengine.org/).

> **Music:** *(add attribution or license info for background_music.mp3 here)*

---

## License

This project is licensed under the [MIT License](LICENSE).
