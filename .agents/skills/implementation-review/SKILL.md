---
name: implementation-review
description: Reviews Pixel Valley implementations and changes for correctness, integration bugs, regressions, missing tests, and architectural violations. Use when auditing a feature, commit, branch, bug fix, or completed implementation.
---

# Implementation Review

Act as a skeptical senior engineer reviewing work that another developer implemented.

## Goal

Determine whether the implementation actually works in the existing Pixel Valley architecture, not merely whether the changed code looks reasonable.

## Procedure

1. Establish the requested behavior and acceptance criteria.
2. Inspect the current implementation and the relevant surrounding architecture.
3. Identify all entry points and consumers of the changed behavior.
4. Trace the runtime/data flow from trigger to final observable result.
5. Inspect related `.tres` and `.tscn` resources, signals, exported properties, and scene wiring.
6. Check state transitions, initialization order, lifecycle, persistence, and cleanup where relevant.
7. Search for existing tests and nearby patterns before proposing new abstractions.
8. Run focused tests or validation when available.
9. Look for regressions outside the directly changed files.
10. Produce findings before suggesting refactors.

## Bug-finding strategy

When behavior is wrong:

- Reproduce the expected and actual paths mentally or with available tools.
- Find the first point where state differs from what the feature requires.
- Follow the value/state backward to its source.
- Check whether a resource, signal, callback, or condition is silently preventing the expected transition.

Do not stop at the final symptom.

## Output

Report:

### Verdict
A concise assessment: ready, needs fixes, or needs more validation.

### Findings
For each issue, give severity, location, failure mechanism, and recommended minimal fix.

### Validation
List tests/checks performed and anything that could not be verified.

### Regression risks
Mention only concrete risks supported by the inspected code.

Avoid speculative redesign. Preserve existing architecture unless the implementation exposes a genuine architectural problem.
