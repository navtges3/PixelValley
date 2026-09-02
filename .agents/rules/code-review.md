# Code Review Rule

Use this rule whenever reviewing an implementation, feature branch, commit, or bug fix.

## Review posture

- Treat developer-written code as untrusted until its behavior is understood.
- Review the full execution path, not just the changed lines.
- Prefer finding the first incorrect state, assumption, or transition over describing downstream symptoms.
- Treat `.tres`, `.tscn`, exported properties, resource references, signals, groups, and scene wiring as executable configuration.
- Distinguish definite bugs from risks, design questions, and optional improvements.

## Required review sequence

1. Identify the intended behavior and acceptance criteria.
2. Inspect the changed files and their callers/consumers.
3. Trace initialization, runtime flow, signals, state changes, persistence, and cleanup as applicable.
4. Check integration points and data/resource references.
5. Check existing tests and add or recommend regression coverage where a bug could recur.
6. Look for adjacent regressions caused by changed contracts or assumptions.
7. Only then judge code quality, duplication, or refactoring opportunities.

## Findings

Prioritize findings as:

- **Critical** — crashes, corrupted state/save data, broken progression, or widespread regressions.
- **High** — feature does not work on a normal path or important integration path is broken.
- **Medium** — edge-case correctness or maintainability issue with meaningful impact.
- **Low** — minor cleanup or clarity improvement.

For every substantive finding, include:
- the affected file/location;
- what is wrong;
- why it happens;
- the concrete execution path that exposes it;
- the smallest reasonable fix;
- whether a regression test should cover it.

Do not report stylistic preferences as bugs. Do not rewrite working code merely to make it look different.

## Validation

If tools permit, run the narrowest relevant tests first, then broader validation when practical. If runtime/editor validation cannot be performed, say exactly what remains unverified.
