# Quest System Improvement Plan

## Current state

`QuestManager` supports multiple simultaneous kill quests and tracks each quest in one explicit lifecycle list: `locked_quests`, `offered_quests`, `active_quests`, `ready_quests`, or `completed_quests`. Monster-kill events are forwarded only to active quests. When the final objective is met, the manager moves the quest to `ready_quests`; rewards and follow-up unlocks are applied only during turn-in.

## Goals

1. Support multiple simultaneous main and side quests.
2. Support different objective types without adding a new event handler directly to `QuestManager` for every type.
3. Keep quest progress save-compatible.
4. Give the HUD, quest window, NPC dialogue, and world systems a stable signal API.
5. Keep rewards centralized so every quest type uses the same turn-in path.

## Proposed lifecycle

- **Locked**: prerequisites are not met.
- **Offered**: the quest can be accepted from a board, NPC, or world interaction.
- **Active**: the player accepted the quest and objectives receive progress events.
- **Ready**: every required objective is complete, but rewards have not been claimed.
- **Completed**: rewards were delivered and follow-up quests were unlocked.

Automatic main quests move directly from locked to active. Other quest sources move from locked to offered and must be accepted before they receive progress. Abandoning an active side quest resets its progress and returns it to offered; main quests cannot be abandoned.

## Objective architecture

Move objective-specific progress rules into objective resources rather than expanding `QuestManager` indefinitely.

Planned objective types:

- `KillQuestObjective`: monster ID, amount, optional location.
- `CollectQuestObjective`: item ID and required inventory count.
- `InteractionQuestObjective`: NPC, object, or location interaction ID.
- `TimedQuestObjective`: deadline or elapsed-time limit.

Each objective should expose a common API:

- `is_complete() -> bool`
- `get_progress_text() -> String`
- event-specific update methods or a generic event-consumption method

## Event flow

Gameplay systems emit domain events through `GameState` or a future quest event bus:

- monster killed
- inventory changed / item collected
- interaction completed
- location entered
- time advanced

`QuestManager` forwards relevant events only to active quests. It emits:

- `quest_offered`
- `quest_accepted`
- `quest_abandoned`
- `quest_progress_updated`
- `quest_ready_to_turn_in`
- `quest_turned_in`

UI and NPC systems should subscribe to these signals instead of polling or modifying quest arrays directly.

## Rewards

Keep reward application centralized in `QuestManager.turn_in_quest()`. Expand the reward resource to support explicit item quantities and unique item IDs. Quest objective code should never grant rewards directly.

## Save migration

Quest saves currently use schema version 2. Schema 1 saves migrate the legacy `available_quests` list into `active_quests`, or into `ready_quests` when the saved quest had already met its completion state, so existing progress is preserved.

Quest save compatibility is centralized in `scripts/save/quest_save_migrator.gd`. `quests.json` stores a top-level `schema_version`; files without it are schema 0 and migrate forward one version at a time before `SaveManager` constructs runtime resources.

Migration policy for future objective and lifecycle changes:

1. Increment `QuestSaveMigrator.CURRENT_SCHEMA_VERSION` only when the serialized quest shape changes.
2. Add one `_migrate_vN_to_vN_plus_1()` function and one `match` branch. Each step accepts the previous version and returns the next; do not add compatibility branches to `SaveManager._load_quest()`.
3. Preserve unknown fields while adding explicit defaults for new required fields. Objective records carry a `type` discriminator (`kill` for the current objective) so later objective types can migrate independently.
4. Never discard valid IDs, progress, completion, reward, unlock, category, or source data. Unknown quest IDs are warned about and reconstructed from their embedded snapshot when possible.
5. Malformed lists, records, objectives, and rewards should warn, skip only the unusable portion, and load the rest of the save.
6. Add direct migrator tests for the previous schema, the new schema, malformed input, and round-trip preservation before changing the main loader.

## Implementation order

1. Add lifecycle signals, query methods, and duplicate-ID protection. **Complete.**
2. Add tests or a debug harness for multiple simultaneous kill quests. **Complete.**
3. Add quest category and source metadata: main/side, board/NPC/world. **Complete.**
4. Add save schema version and split offered, active, and ready quests. **Complete.**
5. Refactor the current kill objective behind the shared objective API.
6. Add collect objectives and inventory progress events.
7. Add interaction/delivery objectives and NPC quest givers.
8. Add timed objectives as a stretch feature.
9. Expand reward entries for quantities and unique items.

## Related issues

- #94 Side quest system design
- #95 QuestManager multi-quest support
- #96 Fetch/collect quest type
- #97 Delivery/talk-to-NPC quest type
- #98 Timed challenge type
- #99 Side quest NPC dialogue and givers
- #100 Side quest rewards
