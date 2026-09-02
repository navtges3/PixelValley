---
name: dialogue-debugging
description: Diagnoses Pixel Valley dialogue failures involving NPC interactions, conversation selection, DialogueRunner state, dialogue resources, conditions, responses, and quest-driven follow-up content. Use when dialogue does not start, the wrong UI opens, a line/branch is missing, or a follow-up conversation is unreachable.
---

# Dialogue Debugging

Use a data-and-execution-path approach. Do not assume the dialogue resource is the root cause.

## Decision tree

### 1. Does the NPC interaction fire?
- Inspect the interaction area, handler, building/location logic, and player interaction path.
- Confirm the intended NPC interaction is reached.

### 2. Is the intended conversation selected?
- Find the conversation-selection logic.
- Inspect all candidate conversations and their prerequisites.
- Verify quest/state conditions against actual runtime state.

### 3. Is the conversation accepted by the runner?
- Trace `DialogueRunner` startup and validation.
- Check `start_entry_id`, entry IDs, links, conditions, and invalid-data handling.
- Check whether an existing conversation is still active or interrupted.

### 4. Does the UI display the conversation?
- Trace runner signals into the dialogue UI.
- Check whether another interaction mode, such as a shop, is being opened instead.
- Check cancellation and completion callbacks.

### 5. Does completion unlock the next content?
- Trace dialogue actions into quest/state mutation.
- Verify the state is updated before the next conversation-selection check.
- Verify follow-up resources reference the correct IDs and conditions.

## Required checks

- Inspect both code and dialogue `.tres` resources.
- Verify IDs and references manually; do not infer them from filenames alone.
- Check same-frame ordering when quest completion changes dialogue availability.
- Check save/load if the bug can occur after loading a saved game.
- Add a regression test at the narrowest integration boundary that reproduces the failure.

## Common Pixel Valley failure modes

- A shop/building interaction wins before dialogue selection.
- A conversation condition is evaluated before the quest state is updated.
- A follow-up quest/dialogue uses the wrong ID.
- A valid conversation exists but has no reachable start entry.
- Dialogue completion updates one state representation while selection reads another.
- A runner is active, cancelled, or interrupted unexpectedly.

## Completion standard

A dialogue bug is not considered diagnosed until the first incorrect transition is identified and the fix path explains why the expected conversation becomes reachable.
