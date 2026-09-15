# Blueprint — what this agent harness is built on

This doc answers two questions:

1. **On what basis is an agent harness like this built?** — the load-bearing ideas, not the file
   list.
2. **How do I build one for my project?** — run [`PROBE.md`](PROBE.md), a self-contained prompt
   that does it in a repo nobody has ever explained to the model.

Nothing here is Claude-Code trivia. It is a description of *why* the pieces are shaped the way
they are, so the shape can be reproduced somewhere else.

Worked examples are drawn from the origin repo — a self-hosted video-streaming platform with a
TypeScript SPA, several Go services and a native Android client. They are labelled **[origin]**
and are illustrations, never requirements. Your repo will produce different ones.

---

## The substrate

The harness sits on five Claude Code primitives and nothing else:

| Primitive | Where it lives | What it buys |
|---|---|---|
| Project memory | `CLAUDE.md`, `.claude/rules/*.md` | facts every session must not re-derive |
| Subagents | `.claude/agents/*.md` | separate context windows + per-agent tool scoping |
| Skills | `.claude/skills/*/SKILL.md` | procedures loaded on demand, not on every prompt |
| Hooks | `.claude/settings.json` → shell scripts | deterministic work removed from the model |
| MCP profiles | a lean default manifest + an opt-in ops one | tool surface kept small per session type |

Everything else — the agent-memory tree, the scratch workspace, the model-tiering table — is a
convention layered on top of those five.

---

## The nine principles

### 1. Context is the budget, not tokens-per-message

Every design choice optimises for *what stays out of the main context window*. The orchestrator
states it as a hard rule: the expensive main thread does research-spawn, gate, and final report —
nothing else. Subagents write detail to a scratch directory and return a terse receipt plus a
path. A one-line fix typed inline by the main thread is treated as a defect, because it spends
the expensive context on work a cheap model could do.

The same instinct drives the output-cap hook (a 4 000-line test log never enters context),
compression skills for subagent receipts, and a lean default MCP profile — every connected server
adds instruction text to *every* prompt of *every* session.

### 2. Ownership boundaries are derived from write-collisions, not from org charts

The rule: **one agent per tree that no other agent writes to.** Where two agents must touch the
same file, either sequence them explicitly or hand one a git worktree.

**[origin]** The frontend agent and the backend agents run in parallel freely — disjoint trees.
Two backend agents are explicitly *forbidden* from running in parallel, because both write under
the same service tree and share one route-wiring file. That single sentence is what makes
parallelism safe; without it the roster is decoration.

A repo with one real tree gets one builder. That is the correct answer, not a failure of the
exercise.

### 3. Model tiering is a written policy, not a vibe

Strongest tier = research, security, compliance, planning, the gate. Mid tier = build, QA,
live-verify. Cheapest tier = pure lookup fan-outs. State it in `CLAUDE.md`, restate it in the
orchestrator skill, and pin it per agent in frontmatter (`model:`) so it survives an operator who
forgets it.

### 4. Exactly one interactive checkpoint

A go/no-go gate after research, before any code — and the skill must say it *must actually halt*.
Before it: research only. After it: the remaining phases run unattended. A pipeline with a gate
per phase is a chat; a pipeline with none is a runaway. One gate, placed where the cost of being
wrong is still zero, is the useful shape.

### 5. Hard constraints are enumerated because they are unguessable

The constraints block exists precisely for facts whose violation *looks like an improvement*.

**[origin]** A misspelled database table is frozen and must never be renamed. A port number is
compiled into the frontend. One API surface must never be mocked in end-to-end tests. None of
these are inferable from the code — a competent model will "fix" every one of them.

If your constraints block comes out empty, the interview missed something. Ask again.

### 6. Agents carry durable memory, indexed

`.claude/agent-memory/<agent>/` holds per-issue findings behind a `MEMORY.md` index of one-line
summaries. Each agent's prompt says *read this before re-exploring*. This is the harness's only
compounding asset.

**[origin]** The frontend index alone encodes two dozen traps — which event a media library emits
its bandwidth sample on, that Kotlin block comments nest — that cost a debugging session each to
learn and would otherwise be relearned every time.

The index matters as much as the entries: a flat pile of notes nobody reads is worse than none.

### 7. Least privilege on tools, for a stated reason

Builder agents get files + shell + web-docs lookup, and nothing else, *because they process
untrusted content* — web pages, third-party metadata — and must not be steerable into messaging
or MCP tools. QA and auditor agents have no edit tool at all: they report, they never fix.

Every agent file says what to do when a task seems to need a missing tool: **stop and report**,
never work around it.

### 8. Say which gate ran, and which didn't

Make the gate's identity and its gaps a first-class output. A reduced-environment session must
state in the PR body what did not run. A missing dependency that only the environment owner can
add is defined as a **reportable finding, never a workaround target**.

Honesty about coverage is load-bearing precisely when nobody downstream re-checks.

### 9. A green fast gate is not a verified branch

Gates tier themselves as a repo grows: a fast pre-merge tier, a slow nightly tier, and sometimes
an automated triage tier after a nightly red. The failure mode is social, not technical — people
read "green" as "verified" and stop looking.

So the harness must write down, in `CLAUDE.md`, **which surfaces the fast tier does not cover**
and what the author is therefore expected to run locally before merging. Every tier should invoke
the *same* task-runner targets a human runs locally, so there is one definition of the gate rather
than a CI file that has quietly drifted from the Makefile.

---

## The pipeline, abstractly

```
research → GATE → build (parallel, ownership-scoped) → verify (QA ∥ security ∥ compliance?)
        → one combined fix loop → live-verify → regression test → report
```

Two details do the heavy lifting and both are easy to drop when copying the shape:

- **One combined fix loop.** QA and security findings are collected into a single re-run of the
  owning specialist, not two sequential cycles.
- **Test-feasibility triage before writing a test.** Decide "needs a real end-to-end test" vs
  "a unit test is sufficient" *first*, and forbid faking the former by mocking the very boundary
  under test. A test that asserts nothing is worse than an admitted gap.

---

## Environment-shape overrides

The base memory file describes **one** machine. Every other machine shape gets a rules file that
says which parts to ignore and what to do instead, keyed on an environment variable.

**[origin]** A cloud-session rules file overrides the base memory when a remote flag is set: no
second terminal, a different gate command, an explicit list of what is unavailable (a missing API
key, cluster access, browser automation) and a failure-triage table for the boot script. Without
it, a cloud session cheerfully runs a foreground dev server and hangs forever.

---

## Two things this kit deliberately does not ship

The origin harness grew two pieces of automation around itself. Both are welded to that repo's
stack, so the kit ships their **lessons** and not their code. Build your own only once you feel
the pain they solve.

### Unattended small fixes

A supervisor picks up issues carrying a specific label, runs an agent per fix in an isolated
checkout, gates it, and merges.

- **The supervisor is bash, never an agent session.** It has to outlive the thing that runs out
  of tokens.
- **Bash owns the gate and the merge, not the agent.** An agent asked to judge its own work will
  eventually pass it.
- **The label is the consent boundary, and must be enforced twice.** Listing issues by a
  *non-existent* label returns *every open issue* at exit 0 — a single-check design silently
  escalates to "edit everything".
- These PRs are gated more weakly than a human's, and nobody reads the diff. Write that down.

### Parallel development lanes

Several agents building at once, each in its own git worktree with its own ports, database and
containers, offset by lane number.

- Parallel agents need **isolated ports, database and state directory**, or they overwrite each
  other's fixtures and you debug a race that does not exist.
- A **shared temp path** (one hardcoded log or output file) silently cross-contaminates lanes —
  this is the single most common bug in such a setup.
- Give agents **disjoint file sets** up front; let the main thread commit the slices.

---

## Rebuilding this elsewhere

[`PROBE.md`](PROBE.md) is the portable version: a prompt that carries these principles and zero
facts about any particular project. Dropped into an unknown repo it reconnoiters the code,
interviews the human for the things reconnaissance cannot reveal, derives an agent roster from
real write-boundaries, and writes the harness — then grades itself against
[`CHECKLIST.md`](CHECKLIST.md) instead of declaring success.
