# Dialogue State Persistence

Dialogue saves contain only durable facts that cannot be reconstructed from another game system.

## Persisted facts

- A one-time introduction has been viewed.
- A non-quest, one-shot NPC action has completed.
- A permanent dialogue choice must change future conversations.

Facts are scoped by the stable `NpcData.npc_id` and use a stable, snake_case fact ID. They are claimed through the `set_dialogue_fact` action and checked through the `dialogue_fact_set` condition.

## Derived state

The following must not be written to `dialogue.json`:

- Quest lifecycle state or objective progress.
- Quest-available, new-conversation, or ready-to-turn-in indicators.
- Delivery item availability.
- Main-story progression.
- NPC services, location, visuals, or authored conversation data.
- The currently open conversation, entry, page, or focused response.

These values are rebuilt from `QuestManager`, inventory, world state, `NpcData`, and the active UI whenever dialogue opens.

## One-shot actions

`DialogueState.claim_fact()` is atomic: the first claim returns `true` and later claims return `false`. Any future non-quest action that grants an item or changes permanent world state must claim its durable fact before applying the effect. Quest rewards remain protected by `QuestManager` and must not receive duplicate dialogue facts.
