# Quest system regression testing

Run the complete automated test suite from the repository root:

```powershell
godot_console.exe --headless --path . res://tests/test_suite.tscn
```

The command exits with code `0` when the Effects and Quests sections both pass. Quest tests use isolated save slots `999998` and `999999` and remove them before exiting.

The quest test section verifies:

- one goblin kill progresses two matching active quests;
- an unrelated orc quest emits no progress event;
- progress and ready-to-turn-in events do not repeat;
- locked side quests move through offered, active, ready, and completed states;
- accepting an offered quest removes it from the offered list;
- abandoning a side quest resets its progress and offers it again;
- main quests cannot be abandoned and duplicate quest IDs are rejected;
- turning in one quest preserves the state of another active quest;
- active, unrelated, and turned-in quest state survives save/load;
- the manager replaced during loading no longer receives monster-kill signals;
- schema 0 and schema 1 saves migrate legacy `available_quests` records safely;
- malformed and newer-schema quest documents preserve all recognized data;
- quest 1 starts active on a new game and progresses from a goblin kill in the forest.

For a manual smoke test, start a new game, defeat one goblin in the Goblin Forest, and confirm **Clear the Path** shows `1 / 3`. Save and reload, defeat another goblin, and confirm it advances to `2 / 3` exactly once.
