# Quest system regression testing

Run the complete automated test suite from the repository root:

```powershell
godot_console.exe --headless --path . res://tests/test_suite.tscn
```

The command exits with code `0` when the Effects and Quests sections both pass. The quest section uses save slot `999999` and removes that slot before exiting successfully or unsuccessfully.

The scenario verifies:

- one goblin kill progresses two matching active quests;
- an unrelated orc quest emits no progress event;
- progress, completion, and ready-to-turn-in events do not repeat;
- turning in one quest preserves the state of another active quest;
- active, unrelated, and turned-in quest state survives save/load;
- the manager replaced during loading no longer receives monster-kill signals;
- quest 1 remains available on a new game and progresses from a goblin kill in the forest.

For a manual smoke test, start a new game, defeat one goblin in the Goblin Forest, and confirm **Clear the Path** shows `1 / 3`. Save and reload, defeat another goblin, and confirm it advances to `2 / 3` exactly once.
