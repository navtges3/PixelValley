# Review Implementation

Review a completed Pixel Valley implementation as a senior engineer. The goal is to determine whether the implementation is actually correct, integrated, testable, and safe—not merely whether the edited code looks reasonable.

## Input

The user may provide an issue number, feature description, commit, branch, or changed files. If the target is ambiguous, inspect the current branch and recent changes rather than guessing.

## Workflow

### 1. Establish the change boundary

- Identify the issue or requested behavior being implemented.
- Inspect the relevant diff and changed files.
- Read `AGENTS.md` and the applicable `.agents/rules/` and `.agents/skills/` guidance.
- Distinguish intentional changes from unrelated modifications.
- Do not assume the changed files are the complete implementation surface.

### 2. Trace the implementation end to end

Follow the actual execution path from the initiating event to the final observable result.

For gameplay features, explicitly trace as applicable:

`player/NPC interaction → manager/system → conditions/state → resource data → action/transition → UI/gameplay result → persistence`

Check both sides of important boundaries:

- scene → script
- UI → manager
- manager → resource
- quest → dialogue
- dialogue → quest/state
- combat → victory/quest progression
- runtime state → save/load

Find the **first incorrect state, value, condition, or transition**, rather than only describing the final symptom.

### 3. Inspect data and configuration

Treat `.tres`, `.tscn`, JSON, and other data files as part of the executable implementation.

Verify:

- IDs and references are valid.
- Resource types match expected consumers.
- Conditions/actions point to the intended IDs.
- Scene node paths and signal connections are valid.
- Default values do not accidentally bypass or block the feature.
- Save/load reconstruction preserves the relevant state.

### 4. Look for integration failures

Specifically search for:

- code paths that are implemented but never called
- signals emitted but never consumed
- signals consumed with incompatible assumptions
- resources created but never assigned/loaded
- conditions that can never become true
- state that is updated in one manager but read from another stale source
- ordering/lifecycle problems caused by `_ready()`, `add_child()`, deferred calls, or initialization timing
- UI behavior that bypasses the intended gameplay flow
- quest/dialogue transitions that work in isolation but fail in the real NPC interaction path
- persistence bugs where the feature works until reload
- regressions in existing behavior

### 5. Review tests

Determine whether existing tests actually cover the changed behavior.

- Read relevant tests before judging coverage.
- Prefer extending existing test patterns over inventing a parallel framework.
- Identify missing tests for the highest-risk paths.
- Pay particular attention to boundary conditions, invalid data, repeated interaction, reload, cancellation, interruption, and progression state.
- Do not treat a passing unit test as proof that integration works.

If tests can reasonably be run, run them or inspect available project test commands. If execution is unavailable, clearly distinguish static analysis from runtime validation.

### 6. Check regression risk

Compare the implementation against neighboring systems and existing conventions.

Ask:

- Could this change alter behavior outside the requested feature?
- Does it duplicate an existing source of truth?
- Does it introduce a second way to perform an existing operation?
- Does it silently change data semantics?
- Does it rely on ordering that is not guaranteed?
- Does it make future content creation harder?
- Does it create technical debt that will compound as Pixel Valley grows?

### 7. Produce findings

Prioritize findings by impact:

**BLOCKER** — Feature is broken, corrupts state/data, crashes, or creates a severe regression.

**HIGH** — Important execution path is incorrect or a likely integration bug will prevent intended behavior.

**MEDIUM** — Meaningful correctness, maintainability, testability, or edge-case issue.

**LOW** — Minor issue, cleanup, or improvement that does not materially affect current behavior.

For every finding include:

1. What is wrong.
2. Where it occurs.
3. Why it matters at runtime.
4. The execution path or evidence that demonstrates the problem.
5. A focused recommendation.

Do not report speculative issues as definite bugs. Label uncertainty explicitly.

### 8. Give an implementation verdict

End with one of:

- **READY** — implementation appears correct and sufficiently validated.
- **READY WITH FOLLOW-UP** — implementation is functionally sound, but worthwhile non-blocking improvements remain.
- **CHANGES REQUIRED** — one or more correctness/integration issues must be addressed.
- **CANNOT VALIDATE** — insufficient evidence or unavailable runtime validation prevents a reliable verdict.

## Review Principles

- Be skeptical of the implementation, not hostile to the developer.
- Prefer evidence from the repository over assumptions.
- Trace behavior instead of judging isolated functions.
- Do not rewrite working code merely to match personal style.
- Do not silently make game-design decisions.
- Keep recommendations minimal and consistent with existing architecture.
- When a bug is found, identify the smallest architectural fix that addresses the root cause.
- If the implementation is good, say so clearly; do not manufacture findings.
