# Pixel Valley

[![Play on itch.io](https://img.shields.io/badge/🎮_Play_on-itch.io-red?style=for-the-badge)](https://fissionwizzard.itch.io/pixel-valley)
[![Feedback](https://img.shields.io/badge/📝_Give-Feedback-green?style=for-the-badge)](https://docs.google.com/forms/d/e/1FAIpQLSfSQfVvR3tb8YQT35z_nKu22EymHAmQoNdFdEDBGPzVtnijzw/viewform)

A solo-developed fantasy JRPG built with Godot. Choose a hero, defend your village, complete quests, explore the world, and battle increasingly dangerous monsters.

Pixel Valley is a personal learning project focused on building a modular, data-driven RPG architecture in Godot using GDScript and Resources.

---

## Overview

Pixel Valley is a single-player turn-based RPG where players choose a hero class, accept quests, upgrade equipment, and explore the surrounding world to protect their village from growing threats.

The game emphasizes a data-driven design. Heroes, monsters, abilities, weapons, quests, rewards, and effects are defined through Godot Resources, making the game easy to extend without modifying core systems.

---

## Current Features

### Combat

- Turn-based combat system
- Energy and cooldown based abilities
- Conditional monster AI
- Buff and debuff effects
- Class-specific weapons and abilities

### Heroes

- Knight
- Assassin
- Princess

Each class features unique stats, abilities, and equipment progression.

### Village Systems

- Weapon Shop
- Potion Shop
- Inn
- Quest Board

### Quests

- Main quest chain with 15+ quests
- Unlockable progression through world areas
- Gold, experience, weapon, and item rewards

### Exploration

- Village hub
- Goblin Forest
- Orc War Camp
- Ogre Cave

### Persistence

- Multiple save slots
- Persistent game state
- Quest progression saving
- Inventory and equipment saving

---

## Getting Started

1. Install Godot 4.6+
2. Clone this repository
3. Open `project.godot`
4. Press **F5** to run

No external plugins are required.

---

## Project Structure

```text
autoload/       Global systems and managers
assets/         Sprites, tilesets, UI assets
audio/          Music and sound effects
resources/      Data-driven game content (.tres)
scenes/         Game scenes
scripts/        Gameplay and UI logic
```

---

## Development Roadmap

### In Progress

- Interior/exterior building transitions
- Village interior polish
- Overworld improvements
- Controller support

### Planned

- Side quests
- Additional quest types
- Status effects
- Combat animations
- Audio and music pass
- Expanded monster roster
- Additional weapons and equipment
- Visual polish

---

## Play the Latest Build

https://fissionwizzard.itch.io/pixel-valley

---

## Credits

Developed by Nick Avtges using Godot Engine.

---

## License

This project is licensed under the MIT License.
