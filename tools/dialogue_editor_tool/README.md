# Pixel Valley Dialogue Editor

A standalone Godot scene that gives you a purpose-built editor for
`DialogueConversation` resources, instead of wrangling nested arrays of
sub-resources in the inspector.

It is **not** an editor plugin/dock — it's a runnable scene you open and
play (F6) from inside the Godot editor whenever you want to work on
dialogue. It uses `FileDialog` with resource-filesystem access, so it can
browse and read/write any `.tres` file in your project while running
inside the editor.

## Install

1. Copy the whole `dialogue_editor_tool` folder into your project at:
   `res://tools/dialogue_editor/`
   (If you'd rather put it somewhere else, open `dialogue_editor.tscn` in
   a text editor and fix the `path=` in the `ext_resource` line to match,
   or just open the scene in Godot — if the script is missing it'll
   prompt you to reassign it, and you can drag `dialogue_editor.gd` onto
   the root node manually.)
2. Open `dialogue_editor.tscn` in the Godot editor.
3. Make sure it's the scene in focus, then press **F6** ("Run Current
   Scene") to launch it. You don't need to set it as your main scene.

Because it relies on your existing `DialogueEntry`, `DialogueCondition`,
`DialogueAction`, `DialogueResponse`, `DialogueSpeaker`, and
`DialogueConversation` scripts (via their `class_name`s), it'll pick those
up automatically as long as they're already in your project — no path
wiring needed on your end.

## What it does

- **New / Open / Save / Save As** a `DialogueConversation` `.tres` file,
  via `res://`-rooted file dialogs.
- Left panel: conversation-level fields (`conversation_id`,
  `start_entry_id`, `can_cancel`) plus the list of entries — select, add,
  duplicate, or delete an entry.
- Right panel: full editor for the selected entry —
  - `entry_id`
  - Speaker: reuse an existing speaker already used elsewhere in the
    conversation (matching how the source `.tres` files share one
    `DialogueSpeaker` sub-resource across entries), or create a new one;
    edit `speaker_id`, `display_name`, and pick a `portrait` texture from
    the project.
  - Pages: add/remove/reorder multiline text pages.
  - Flow: `next_entry_id` / `skip_entry_id`, each with a dropdown of the
    conversation's current entry ids so you don't have to remember/retype
    them.
  - Conditions and Actions: add/remove any number, each with a
    `condition_id`/`action_id` and a free-form parameters editor
    (key + type + value, matching the `Dictionary[StringName, Variant]`
    shape used by `DialogueCondition`/`DialogueAction`).
  - Responses: add/remove any number, each with its own text,
    `next_entry_id`, and its own nested conditions/actions.
- Bottom panel: live **validation** — flags dangling `next_entry_id` /
  `skip_entry_id` / response references that don't point at an existing
  entry in the conversation, duplicate or empty `entry_id`s, entries
  missing a speaker or pages, and responses with empty text. It re-checks
  after every edit.

## Known limitations

- Renaming an `entry_id` does **not** automatically update other entries'
  `next_entry_id`/`skip_entry_id`/response references to it — the
  validation panel will flag anything that's now dangling so you can fix
  it by hand.
- No undo/redo inside the tool — it edits the loaded resource objects
  directly. Keep your project under version control (which you already
  do) and commit before big edits if you want a safety net.
- The portrait file picker and the open/save dialogs use
  `FileDialog.ACCESS_RESOURCES`, which only works when the scene is run
  from inside the editor (exactly how this tool is meant to be used) —
  it won't work in an exported build.
