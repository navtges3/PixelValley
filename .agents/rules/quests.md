# Quest Rule

Apply this rule when working on quests, quest progression, quest conditions/actions, NPC quest integration, or quest-driven world state.

- Treat `QuestManager` as a Resource owned by `GameState`; do not assume it is an autoload.
- Trace quest progression end to end: trigger → condition → quest state mutation → persistence → dependent systems → next available interaction/content.
- Verify every quest ID and prerequisite relationship against the actual resources and code.
- Check the distinction between accepted, active, completed, failed, and unavailable states wherever the project supports them.
- When a quest unlocks dialogue, locations, shops, battles, rewards, or follow-up quests, verify the consumer actually observes the updated state.
- Pay particular attention to timing: state changes made during interaction may not be visible to code that already selected content earlier in the same interaction.
- Check save/load reconstruction when quest state affects progression.
- Prefer integration tests for quest-to-NPC/dialogue progression rather than testing only isolated quest methods.

When debugging a missing follow-up quest or interaction, build a prerequisite chain and identify the first prerequisite that is false or never propagated. Do not assume the missing content resource itself is the problem.
