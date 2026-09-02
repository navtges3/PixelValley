---
name: issue-outline
description: Analyzes a Pixel Valley GitHub issue and the existing codebase to produce an implementation outline. Activate when the user asks to "outline issue #xxx", asks how an issue should be implemented, or wants to know what files, systems, resources, tests, and integration points need to change before starting work.
---

# Issue Outline

Act as a senior engineer helping the developer plan an issue before implementation begins. The goal is to turn a GitHub issue into a concrete, repository-aware implementation plan without writing the implementation itself.

## Core principle

**Understand the existing system before proposing changes.**

Do not infer the solution from the issue description alone. Inspect the repository, existing architecture, and nearby implementations first. Prefer extending established patterns over introducing new abstractions.

## Procedure

1. Read the complete GitHub issue, including acceptance criteria, linked issues, and relevant discussion when available.
2. Establish the requested behavior and identify anything that is ambiguous or intentionally left as a design decision.
3. Inspect `AGENTS.md` and any applicable Antigravity rules and skills.
4. Search the repository for the systems, classes, resources, scenes, signals, IDs, and patterns involved.
5. Trace the existing runtime/data flow that the issue will affect.
6. Identify the smallest set of files that should likely change.
7. Identify files that may need to be inspected but should not necessarily change.
8. Check `.tres` resources, `.tscn` scenes, exported properties, resource references, signal connections, and data IDs whenever the feature touches data-driven behavior.
9. Inspect existing tests and determine the focused tests that should be added or updated.
10. Look for integration boundaries and lifecycle/order-of-initialization concerns before finalizing the outline.
11. Produce an implementation sequence that is practical to execute one step at a time.
12. Call out uncertainties or decisions that should be resolved before coding.

## What to investigate

For each issue, consider the relevant layers:

- **Data:** Resources, `.tres` files, IDs, configuration, databases/loaders.
- **Core logic:** Managers, Resources, state transitions, business rules.
- **World/scene:** `.tscn` files, nodes, interactions, triggers, scene wiring.
- **UI:** Screens, HUDs, signals, user actions, presentation state.
- **Integration:** Quest ↔ dialogue, combat ↔ abilities, world ↔ GameState, save/load, etc.
- **Persistence:** What state must survive scene changes or save/load?
- **Testing:** Unit, integration, resource/data validation, and regression coverage.

Do not mechanically inspect every layer. Focus on the layers affected by the issue.

## File recommendations

For every proposed change, provide:

- Exact repository path when known.
- What should change there.
- Why that file is the appropriate location.
- Whether it is a **change**, **new file**, or **inspection only**.

If the exact file cannot be determined without implementation discovery, say so instead of guessing.

Distinguish clearly between:

- **Must change** — required for the issue.
- **Likely change** — strongly indicated by the existing architecture but may depend on implementation details.
- **Inspect only** — relevant context or integration point that should be checked but should not be modified by default.

## Code examples and structure outlines

Code examples are encouraged when they clarify the intended structure. Examples should be small and representative rather than complete implementations.

Use examples to show things such as:

- A new method or signal signature.
- How an existing manager should be called.
- A proposed Resource/property structure.
- A scene/node relationship.
- A data flow between existing systems.
- A focused test shape.

Clearly label examples as illustrative. Do not invent APIs that conflict with the repository's existing patterns.

When a code example would be premature, use a structural outline instead:

```text
Issue trigger
    ↓
Existing system/class
    ↓
New or modified state/data
    ↓
Existing consumer
    ↓
Observable result
```

## Implementation sequence

Give a numbered sequence that follows dependencies and minimizes rework. Prefer small, independently understandable steps.

For example:

1. Extend the existing Resource/data model.
2. Update the loader or manager that owns that data.
3. Connect the existing interaction/scene path.
4. Add or update the integration test.
5. Validate the complete runtime path.

Do not prescribe a sequence that assumes files should be changed merely because they are related.

## Testing plan

For each meaningful behavior, identify:

- Existing test that should cover it, if one exists.
- New focused test that should be added.
- Integration path that should be manually validated.
- Persistence/reload validation when relevant.

Favor tests that prove the issue's acceptance criteria and the most likely regression boundary.

## Output format

### Issue Summary
Restate the requested behavior briefly and identify the primary systems involved.

### Existing Architecture
Explain the current path through the relevant systems. Include a compact structure/data-flow outline when useful.

### Proposed Changes
Group files by **Must change**, **Likely change**, and **Inspect only**. For each file, explain what belongs there and why.

### Implementation Sequence
Provide a numbered, dependency-aware sequence of changes.

### Code / Structure Examples
Include concise GDScript or structural examples where they make the plan easier to implement. Avoid unnecessary boilerplate.

### Testing Plan
Identify focused automated tests and manual integration checks.

### Risks / Integration Points
List concrete risks such as signal wiring, initialization order, resource references, quest/dialogue state, scene lifecycle, or save/load behavior.

### Open Questions
Only include questions that genuinely block or materially affect the implementation. Do not invent uncertainty.

### Definition of Done
Translate the issue's acceptance criteria into a short implementation checklist.

## Boundaries

- This skill plans the implementation; it does not implement the issue unless explicitly asked afterward.
- Do not redesign the architecture just because another approach looks cleaner.
- Do not assume every issue requires a new class, manager, Resource, scene, or abstraction.
- Do not list files simply because they contain related concepts; tie every proposed change to a concrete behavior.
- Do not silently make game-design decisions. Surface them as open questions when necessary.
- If the issue is underspecified, provide the useful portion of the outline and clearly identify what is missing.
- If repository evidence contradicts the issue description, call that out explicitly.
