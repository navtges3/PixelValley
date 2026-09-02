---
name: quest-debugging
description: Diagnoses Pixel Valley quest progression failures, missing prerequisites, incorrect quest states, NPC quest integration, follow-up unlocks, persistence issues, and quest-driven dialogue or world-state bugs. Use when a quest cannot start, complete, unlock its next step, or propagate progression.
---

# Quest Debugging

Treat quest progression as a chain of state transitions and dependencies.

## Procedure

1. Identify the expected quest progression and exact quest IDs.
2. Build the prerequisite chain from the current state to the missing behavior.
3. Locate the code/resource that establishes each prerequisite.
4. Verify the runtime quest state rather than relying only on resource definitions.
5. Trace every consumer that depends on the changed state.
6. Check interaction ordering when progression occurs during an NPC interaction, battle, reward, or dialogue completion.
7. Check persistence/reconstruction if progression survives saves.
8. Compare the failing path with a nearby working quest using the same architecture.
9. Add or recommend a focused integration regression test.

## State questions

For each failed transition, answer:

- What state should exist?
- Where is that state created or changed?
- When is it changed?
- Who reads it?
- Is the reader guaranteed to observe the new value?
- Can a stale object/resource/cache be involved?
- What happens after save/load?

## Follow-up content

For missing dialogue, quests, rewards, locations, or interactions:

- Verify the predecessor actually reaches its terminal state.
- Verify the follow-up ID/reference is correct.
- Verify the follow-up condition is satisfiable.
- Verify the selection/consumer code actually checks that follow-up.
- Verify no higher-priority interaction path prevents it from being reached.

## Completion standard

Do not call a quest progression issue resolved merely because the quest state changes. Confirm that the next dependent system observes the change and that the player can reach the intended next step.
