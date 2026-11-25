---
name: hey
description: Entry point for a working session - loads the index of principles Claude cites while it works and routes the request to the skill that fits. Typed by the user as /hey, alone or with a request ("/hey この issue やって").
disable-model-invocation: true
---

# hey

> The pstack principles and their index lines come from [cursor/plugins](https://github.com/cursor/plugins/tree/aaeb0ea3a0584995aa8f55ce44c6c5259414b896/pstack) (pstack, MIT, Lauren Tan), unchanged. The copy Claude reads is pinned in `flake.nix`.

Where anything here or in a principle conflicts with CLAUDE.md, CLAUDE.md wins.

If the command came with a request, carry it out under these rules. If it came alone, say in one line that the principles are loaded and wait for the request.

## Citing principles

- When a principle applies, read its body in full before acting on it.
- In the reply, name each principle that shaped a decision and the specific choice it changed.
- Cite only principles whose body you read in this session.

## pstack principles

Each body is `~/.claude/pstack/skills/<name>/SKILL.md`, with `<name>` the one in backticks. Each entry names when it applies. A body that points to another pstack skill means `~/.claude/pstack/skills/<that skill>/SKILL.md`; read it the same way, and map any Cursor name in it with `~/.claude/pstack/docs/harness/claude-code.md`.

**Core**

- **Laziness Protocol** (`principle-laziness-protocol`). Refactoring, sizing a diff, or tempted to add abstractions, layers, or signal threading. Bias to deletion and the smallest change that solves the problem.
- **Foundational Thinking** (`principle-foundational-thinking`). Before writing logic: core types and data structures, scaffold-vs-feature sequencing, what concurrent actors share.
- **Redesign from First Principles** (`principle-redesign-from-first-principles`). Integrating a new requirement into an existing design. Redesign as if it had been foundational from day one.
- **Attack the Premise** (`principle-attack-the-premise`). Two or more fixes that share one premise have failed the same gate. Write the premise down and test it directly before you write another fix that assumes it.
- **Subtract Before You Add** (`principle-subtract-before-you-add`). Sequencing an addition, refactor, or rewrite. Remove dead weight first, then build on the simpler base.
- **Minimize Reader Load** (`principle-minimize-reader-load`). Reviewing or shaping code that's hard to trace. Count layers and hidden state, collapse one-caller wrappers, shrink mutable scope.
- **Outcome-Oriented Execution** (`principle-outcome-oriented-execution`). Planned rewrites and migrations with explicit phase boundaries. Converge on the target architecture, don't preserve throwaway compatibility states.
- **Experience First** (`principle-experience-first`). Product, UX, or feature-scope tradeoffs. Choose user delight over implementation convenience.
- **Exhaust the Design Space** (`principle-exhaust-the-design-space`). A novel interaction or architectural decision with no precedent. Build 2-3 competing prototypes and compare before committing.
- **Build the Lever** (`principle-build-the-lever`). Any non-trivial work. Build the tool that does or proves it (codemod, script, generator), not by hand. The tool is the artifact a reviewer reruns.

**Architecture**

- **Model the Domain** (`principle-model-the-domain`). Writing stateful logic, or code that branches a lot or repeats a shape assumption across files. Encode the domain in a structure (state machine, typed model, table or registry, reducer, boundary, the right collection) instead of scattered conditionals.
- **Boundary Discipline** (`principle-boundary-discipline`). Wiring validation, error handling, or framework adapters. Guards at system boundaries, trust internal types, keep business logic pure.
- **Type System Discipline** (`principle-type-system-discipline`). Designing types or a signature in any typed language. Make illegal states unrepresentable, brand primitives, parse external data at boundaries.
- **Make Operations Idempotent** (`principle-make-operations-idempotent`). Designing commands, lifecycle steps, or loops that run amid crashes and retries. Converge to the same end state.
- **Migrate Callers Then Delete Legacy APIs** (`principle-migrate-callers-then-delete-legacy-apis`). Introducing a new internal API while old callers exist. Migrate and delete in one wave.
- **Separate Before Serializing Shared State** (`principle-separate-before-serializing-shared-state`). Concurrent actors might write the same file, branch, key, or object. Eliminate the sharing first.

**Verification**

- **Prove It Works** (`principle-prove-it-works`). After a task, before declaring done. Verify against the real artifact, not a proxy or "it compiles".
- **Fix Root Causes** (`principle-fix-root-causes`). Debugging. Trace each symptom back to the first place the system went wrong and fix it there. A guard is a fix only when the state it handles is legitimate.
- **Sequence Work into Verifiable Units** (`principle-sequence-verifiable-units`). Multi-step work (sweeps, migrations, runs of similar edits) and how you stack commits and PRs. Break work into small units that each end in a check, verify each before the next, and order delivery so the sequence proves itself.
- **Test Behavior, Not Implementation** (`principle-test-behavior-not-implementation`). Writing, changing, or keeping a test. Assert what the code's users can observe, so the test fails when that behavior breaks and keeps passing when only the internals change.
- **Explain the Number** (`principle-explain-the-number`). Apply before you measure, and before you trust, report, or act on a number you measured (a speedup, a regression, a throughput, a latency, or an eval result). Find what limits it, and rule out that it measured something other than the work you think.

**Delegation**

- **Guard the Context Window** (`principle-guard-the-context-window`). Context fills up: large outputs, long files, repeated reads, fan-out planning. Route bulk to subagents, keep summaries in the main thread.
- **Never Block on the Human** (`principle-never-block-on-the-human`). Tempted to ask "should I do X?" on reversible work. Proceed, present the result, let the human course-correct.

**Meta**

- **Encode Lessons in Structure** (`principle-encode-lessons-in-structure`). You catch yourself writing the same instruction a second time. Encode it as a lint, metadata flag, runtime check, or script instead of more text.

## Own principles

Each body is `~/.claude/principles/<name>/SKILL.md`, with `<name>` the one in backticks.

None yet.

## Routing

When the request is one of these, load that skill with the Skill tool and follow it. The principles above still apply inside it.

- Shaping work into a spec or issues, or carrying a changed decision into sibling issues → **write-issue**.
- Carrying out one issue → **work-issue**.
- Writing or changing a PR description → **opening-a-pr**.
- Where a PR or issue stands after review, what is left, whether it can merge or close → **close-out**.
- Review comments on the user's own PR, or whether a comment holds → **address-review**.
- Helping the user review someone else's PR, diff, design doc, or spec → **review-companion**.
- Checking out a PR's branch in this session → **load-pr**.
- Understanding a diff, branch, commit, or PR in depth → **explain-diff**.
- A diagram of an issue and its sub-issues or a stack of PRs, for a GitHub body → **draw-scope**.
- Stress-testing a plan or decision → **grilling**. An idea still vague → **idea-refine**.
- Several questions, decisions, or fixes to settle in order → **one-by-one**.
- Japanese text someone else reads → **japanese-writing**. A Notion page → **notion-writing**.
- Friction in how Claude works that should become a skill, setting, or rule → tell the user to type `/retro`; the Skill tool cannot load it.

A request that fits none of these is worked on directly.

## Do not

- Do not cite a principle whose body you have not read in this session.
- Do not follow a pstack instruction that conflicts with CLAUDE.md, such as opening a PR ready for review or proceeding without asking where CLAUDE.md says to ask.
- Do not load poteto-mode or other pstack skills as a whole; this file takes their place.
