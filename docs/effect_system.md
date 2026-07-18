# Effect system lifecycle

The effect system is the single path for applying, querying, ticking, and removing combat effects. In code, the stateless service is named `EffectManager`; "effect system" refers to the architecture as a whole. It is deliberately not an autoload.

## Ownership boundaries

| Type | Owns | Must not own |
| --- | --- | --- |
| `Effect` | Authored, data-only configuration: stable ID, display data, level, duration, persistence, and stat changes | Runtime target/source, remaining duration, applied modifier state, or collection mutation |
| `ActiveEffect` | One runtime application: `Effect`, source, target, remaining future turns, lifecycle revision, and the exact applied-stat ledger | Stacking policy, target collection membership, turn scheduling, or UI state |
| `Combatant` | The authoritative `active_effects` runtime collection attached to that combatant | Identity matching, application rules, ticking, or direct lifecycle removal |
| `EffectManager` | Identity lookup, application/refresh/upgrade policy, turn snapshots, ticking, expiration, removal, cleanup, logging results, lifecycle dispatch, and read-only UI queries | Persistent global state or presentation |

Gameplay and UI callers must not append to, erase from, or decrement entries in `Combatant.active_effects`. They use `EffectManager`. `ActiveEffect` lifecycle methods are implementation details called by `EffectManager`. `SaveManager` is the persistence-boundary exception: it reconstructs saved runtime instances and their recorded modifier ledgers during load without executing application behavior again.

## Application rules

`EffectManager.apply_effect(effect, source, target)` compares the incoming `Effect.level` with the active effect that has the same `effect_id`.

| Existing state | Result | Runtime behavior |
| --- | --- | --- |
| No matching ID | `ADDED` | Create one `ActiveEffect`, apply `ON_APPLY`, then emit `ADDED` |
| Same level | `REFRESHED` | Keep the existing instance and authored effect, restore full duration, update a non-null source, and emit `REFRESHED`; do not run `ON_APPLY` again |
| Lower level | `REJECTED_WEAKER` | Leave effect, source, duration, and stats unchanged, then emit `REJECTED_WEAKER` |
| Higher level | `UPGRADED` | Remove the old instance with `REPLACED`, reverse its ledger, create and apply the higher-level instance, then emit one `UPGRADED` event |

There is at most one active instance of a given `effect_id` on a combatant. Levels of the same logical effect must therefore share one ID. Different effects must have unique IDs even if their display names happen to match.

A same-level refresh intentionally does not execute `ON_APPLY`. This prevents reversible modifiers from stacking. A null refresh or upgrade source preserves the previous source; a non-null source becomes the new source.

## Duration and turn-end timeline

`remaining_turns` means eligible future turns for the affected combatant, not global rounds and not the turn in which a self-effect was just applied or refreshed.

At the start of a combatant's turn, `BattleManager` calls `EffectManager.capture_turn_start(combatant)`. Each snapshot records the active instance and its lifecycle revision. At that combatant's turn end, `process_turn_end()` handles only snapshots whose instance is still attached to the same target and whose revision is unchanged.

For every eligible snapshot, turn-end processing occurs in this exact order:

1. Execute `ON_TICK` changes.
2. Decrement `remaining_turns`.
3. Emit `TICKED` with the post-decrement count.
4. If the count reached zero, reverse recorded modifiers.
5. Execute `ON_EXPIRE`, then `ON_REMOVE`.
6. Erase the runtime instance and emit `REMOVED` with reason `NATURAL`.

After all effects are processed, `BattleManager` refreshes the affected UI and resolves deaths before another action begins. If both combatants are dead at this boundary, hero death has precedence: the result is defeat and no monster rewards are granted. Terminal battle state guards prevent duplicate victory/defeat signals and duplicate rewards.

### Duration-2 examples

```mermaid
sequenceDiagram
    participant H as Hero
    participant EM as EffectManager
    participant M as Monster

    Note over H,EM: Duration-2 self-buff
    H->>EM: capture_turn_start(hero)
    H->>EM: apply self-buff
    EM-->>H: ON_APPLY, ADDED, remaining=2
    H->>EM: process_turn_end(hero, old snapshot)
    Note right of EM: New effect is skipped
    H->>EM: next hero turn start/end
    EM-->>H: TICKED, remaining=1
    H->>EM: following hero turn start/end
    EM-->>H: TICKED remaining=0, reverse, REMOVED

    Note over H,M: Duration-2 DOT applied to target
    H->>EM: apply DOT to monster
    EM-->>M: ADDED, remaining=2; no damage yet
    M->>EM: capture at monster turn start, then process turn end
    EM-->>M: damage tick 1, remaining=1
    M->>EM: next monster turn start/end
    EM-->>M: damage tick 2, remaining=0, REMOVED
```

A target effect applied before that target's turn starts is included in the target's upcoming turn-start snapshot, so its first tick occurs at the end of that upcoming target turn. A self-effect applied after the actor's snapshot is not eligible at the end of the turn in which it was applied.

Refreshing or upgrading increments or replaces lifecycle state, invalidating the old turn-start snapshot. It therefore cannot tick or consume refreshed duration at that same turn end.

## Removal reasons and cleanup

`ActiveEffect.RemovalReason` has five values:

| Reason | Used for | Runs `ON_EXPIRE`? | Runs `ON_REMOVE` and reverses modifiers? |
| --- | --- | --- | --- |
| `NATURAL` | Duration reaches zero | Yes | Yes |
| `CLEANSED` | Explicit early removal | No | Yes |
| `RESTED` | `Combatant.rest()` | No | Yes |
| `BATTLE_ENDED` | Victory, defeat, or flee cleanup | No | Yes |
| `REPLACED` | Higher-level upgrade | No | Yes |

Modifier reversal uses the actual deltas recorded when `ON_APPLY` ran, not newly calculated resource values. Removal is idempotent: a removed effect cannot reverse stats twice. Current HP and current energy changes are outcomes, not reversible modifiers, and remain after the effect is removed.

Battle cleanup uses one authoritative path. Victory, defeat, and flee remove combat-only effects from the hero and every effect from the monster. An effect marked `PERSISTENT` can remain on the hero after combat. Rest removes both combat-only and persistent effects before refilling HP and energy.

## Lifecycle events

`EffectEventDispatcher.lifecycle_event` emits immutable `EffectLifecycleEvent` payloads. `BattleManager` owns one dispatcher and forwards it through `effect_lifecycle_changed` for the battle UI.

Event order follows state mutation: `ADDED`, `REFRESHED`, `UPGRADED`, or `REJECTED_WEAKER` is emitted once after its application decision; `TICKED` is emitted after the decrement; a final `TICKED` precedes one `REMOVED`. An upgrade emits `UPGRADED`, not a separate `REMOVED` for the replaced level.

Each payload exposes `type`, `target`, `effect_id`, current `level`, `previous_level`, `incoming_level`, `remaining_turns`, and `removal_reason`. Source attribution is available on the internal `ActiveEffect`, not in the UI event payload.

## Creating an effect resource safely

1. In Godot, create or duplicate an `Effect` resource under `resources/effects/`. Rename or move referenced `.tres` files only through Godot's FileSystem dock so resource references and UIDs stay valid.
2. Set a non-empty, unique `effect_id: StringName`. Reuse an ID only for stronger levels of the same logical effect. `effect_name` is presentation, never identity.
3. Set `level`, `base_duration`, and optional `duration_per_level`. Duration is clamped to at least one future target turn.
4. Choose `COMBAT_ONLY` unless the effect is intentionally allowed to survive battle cleanup on the hero.
5. Add typed `EffectStatChange` subresources. Set `stat`, `timing`, `operation`, `base_amount`, and optional `amount_per_level`.
6. Put reversible max-HP, max-energy, attack, magic, defense, and resist modifiers at `ON_APPLY`. Their actual deltas are recorded and reversed automatically; do not author a matching inverse change.
7. Use current HP or current energy for one-time, tick, expiration, or removal outcomes. `ON_EXPIRE` runs only on natural expiration; `ON_REMOVE` runs for every removal reason.
8. Reference the effect from an ability or potion resource, then add a focused regression test. `EffectManager.validate_unique_effect_ids()` can validate a collection during tests or tooling.

Modifier stat changes authored for timings other than `ON_APPLY` are ignored as a safety rule. `amount_per_level` contributes only when it is positive in the current API.

## Applying effects from gameplay

Abilities declare `caster_effects` and `target_effects`; `Ability.use()` duplicates each resource and calls `EffectManager.apply_effect()` with the caster as source. Caster effects target the caster, while target effects target the selected combatant.

Potions declare `effects`; `Hero.use_item()` consumes the potion, duplicates each effect, and applies it with the hero as both source and target. New gameplay code should follow these paths or call the manager directly:

```gdscript
var effect_copy: Effect = authored_effect.duplicate() as Effect
var result: EffectManager.ApplicationResult = EffectManager.apply_effect(
    effect_copy,
    caster,
    target,
    0,
    effect_dispatcher
)
battle_log_updated.emit(result.output)
```

Do not append an `ActiveEffect`, call its lifecycle methods, or modify `remaining_turns` from ability, item, battle, or UI code.

## Reading effects in UI

UI code calls `EffectManager.get_active_effects(combatant)`, which returns detached `EffectView` snapshots. A view exposes `effect_id`, `display_name`, `level`, `remaining_turns`, `persistence`, `image`, and `tooltip_text`. Clearing the returned array or retaining a view cannot mutate runtime state.

Use `has_effect()` and `get_effect_remaining_turns()` for focused queries. During battle, listen to `BattleManager.effect_lifecycle_changed` and re-query the affected combatant instead of polling or reading `Combatant.active_effects`.

## Regression tests

Effect coverage lives in `tests/effects/` and is assembled by `tests/test_suite.tscn`. Run it headlessly from the project root:

```powershell
godot --headless --path . --scene res://tests/test_suite.tscn
```

The suites cover identity, application policy, duration snapshots, source/target integration, potions, simultaneous effects, modifier reversal, every removal path, battle cleanup, effect-caused victory/defeat, simultaneous-death precedence, duplicate protection, lifecycle payloads, and UI snapshots.
