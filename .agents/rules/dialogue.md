# Dialogue Rule

Apply this rule when working on dialogue resources, dialogue runner/UI code, NPC interaction flow, or dialogue-driven quest progression.

- Treat dialogue as a data-driven state machine. Validate IDs, entry links, start entries, conditions, actions, response branches, and terminal states.
- Trace the complete path: player interaction → NPC/location handler → dialogue selection → condition evaluation → `DialogueRunner` → UI → dialogue completion/actions → quest/state updates → next interaction.
- When dialogue fails to appear, first determine whether the wrong conversation was selected, the intended conversation was rejected by conditions, the runner failed to start it, the UI opened another mode, or completion/state updates were missing.
- Inspect both code and `.tres` dialogue resources. A syntactically valid resource can still be logically unreachable.
- Check ordering and timing of quest/state updates when dialogue conditions depend on recently completed quests.
- Check cancellation, interruption, completion, invalid data, and response branches—not only the happy path.
- Preserve existing dialogue conventions and resource schemas unless the task explicitly changes them.
- Prefer a focused regression test for every discovered dialogue progression bug.

For debugging, identify the first point at which the expected conversation diverges from the actual state. Do not stop at the visible symptom.
