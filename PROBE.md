# PROBE — build an agent harness for this repository

You are in a repository nobody has described to you. Your task is to build its Claude Code
harness: project memory, a subagent roster, an orchestrator skill, agent memory, hooks, and a
short doc recording what you built and what you could not determine.

This prompt carries **no knowledge of this repo**. Everything you write must trace back to
something you observed here or something the human told you. Anything else goes in the open
questions list — not into `CLAUDE.md`.

Work through the phases in order. Do not skip Phase 2.

---

## Ground rules (apply throughout)

1. **No invented facts.** No port, command, framework version, or convention gets written down
   unless you saw it in a file or were told it. "Probably standard" is not a source.
2. **Verify commands before documenting them.** If you write `make check` into the Definition of
   Done, you must have run it (or at least `make -n`) and know whether it exists and what it
   needs. A gate nobody has ever run is not a gate.
3. **Keep the main memory file short.** `CLAUDE.md` under ~200 lines. Detail belongs in `docs/`.
   Every line in `CLAUDE.md` is re-read in every session forever; earn it.
4. **Prefer deletion to hedging.** A section you cannot ground gets removed, not written
   vaguely.
5. **Budget your own context.** Read heads of files, not whole files. Sample 2–3 files per tree,
   not all of them. You are demonstrating the discipline the harness will enforce.

---

## Phase 1 — Reconnaissance (no writing yet)

Run these and take notes. Adapt to the platform; skip what does not apply.

**Shape and size**

```bash
ls -a
git log --oneline -15
git log --format='%an' -200 | sort | uniq -c | sort -rn | head
find . -maxdepth 2 -type d -not -path './.git*' -not -path '*/node_modules*' | head -50
```

**Languages and entry points** — find the manifests, they name the stack:
`package.json`, `go.mod`, `pyproject.toml`/`requirements.txt`, `Cargo.toml`, `pom.xml`,
`build.gradle*`, `Gemfile`, `*.csproj`, `composer.json`, `mix.exs`, `Makefile`, `justfile`,
`Taskfile.yml`, `docker-compose*.yml`, `Dockerfile*`.

For each manifest found: read its scripts/targets section. **Those names are the vocabulary of
the harness** — the build, test, lint, and dev commands must be quoted verbatim, never
paraphrased.

**Existing agent config** — do not clobber it:

```bash
ls -a .claude .cursor .github 2>/dev/null
cat CLAUDE.md AGENTS.md .cursorrules CONTRIBUTING.md 2>/dev/null | head -120
ls .github/workflows/ 2>/dev/null && head -40 .github/workflows/*
```

If a `CLAUDE.md` or `AGENTS.md` already exists, you are **extending**, not replacing. Say so in
the final report and preserve every constraint already written there.

**CI = the real Definition of Done.** Read the workflow files. Whatever CI runs on a PR is the
minimum bar; note the exact commands and whether they run on PRs at all (triggers may be
disabled — that changes everything, see Phase 2 Q4).

**Test and verification surface**

```bash
find . -type d \( -name test -o -name tests -o -name e2e -o -name __tests__ -o -name spec \) \
  -not -path '*/node_modules/*' | head -20
```

Read one test file per framework. Note: how the suite is invoked, whether it needs a running
service, whether there is any browser/E2E layer, and what the fixture/seed story is.

**Ownership boundaries** — the single most important output of this phase. For each top-level
code tree, determine who writes it and what it imports. Then find the **collision points**: files
that two different trees both modify (route registries, DI containers, schema files, generated
clients, `index` barrels, i18n catalogues, lockfiles).

```bash
git log --format='%H' -300 | while read c; do git show --stat --format= "$c"; done \
  | awk '{print $1}' | grep / | sort | uniq -c | sort -rn | head -30
```

The top of that list is your collision list: high-churn files touched by many otherwise unrelated
changes. They decide which agents may run in parallel.

**Local runnability** — try, briefly, to determine whether the project runs here: does the dev
command exist, are services already up (check listening ports), are there env vars or secrets
required that are obviously absent? Do not spend more than a few minutes; record the answer.

**Write a facts table** (in your reply, not to disk yet): stack, entry points, exact commands,
test layers, collision files, unknowns. Everything after this phase must cite it.

---

## Phase 2 — Interview (the only interactive checkpoint)

Reconnaissance cannot reveal intent. Ask the human, using a question tool if you have one,
otherwise as a numbered list. Ask **only** what you could not determine, and lead with your own
finding so they can just confirm:

1. **The gate.** "I found `<command>` in CI / the Makefile. Is that the command that must pass
   before a commit? Does it need anything running first?"
2. **Hard constraints.** "What must never be changed, even when it looks wrong?" Prompt them:
   frozen names/typos, API response shapes with external consumers, hardcoded ports or paths,
   files that look dead but are not, a legacy contract. **This is the highest-value question in
   the interview** — these are exactly the things a model will confidently "fix".
3. **Definition of Done.** What ships with every change: tests (which kind, at which layer),
   coverage floor, security scans, docs updates, changelog?
4. **Where verification actually happens, and what it misses.** Does CI run on every PR, or is
   the local run the only gate? If local-only, the harness must say so loudly. If CI is tiered
   (a fast per-PR job plus a slower nightly/manual sweep), ask **which surfaces the fast tier
   does not cover** — those are what the author has to run locally before merging, and a green
   fast tier will otherwise be read as "verified".
5. **Ownership.** "I see trees `A`, `B`, `C` and heavy churn in `<collision files>`. Should those
   be separate specialists, and is my collision list right?"
6. **Environment shapes.** Do sessions ever run somewhere other than a dev laptop (cloud VM, CI
   container, devcontainer) where the dev command or the gate differs?
7. **Risk surface.** Does this project handle personal data, payments, licensing/DRM, secrets, or
   anything with a legal/compliance dimension? (Decides whether a compliance auditor exists.)
8. **Live verification.** Is there a running instance, a browser UI, or a staging environment an
   agent may drive to confirm a change works?
9. **Cost posture.** Is a two-tier model policy (expensive for research/security, cheap for
   building) wanted, and is spawning many parallel subagents acceptable here?
10. **Existing tooling** to wire in: MCP servers, linters/formatters run on save, skills or
    plugins already in use.

**Halt until answered.** Then restate the resulting harness plan in ~10 lines — roster, gate,
constraints, pipeline — and get a go before writing files.

---

## Phase 3 — Derive the roster (rules, not taste)

Apply these in order:

1. **One builder agent per tree that no other builder writes to.** Disjoint trees → may run in
   parallel. If two candidate agents both write a collision file from Phase 1, either merge them
   into one agent or declare them **sequential-only** and write that rule into both agent files
   *and* the orchestrator. Never leave it implicit.
2. **A repo with one real tree gets one builder.** Splitting by layer (controllers vs models)
   inside one tree creates collisions and buys nothing. Resist it.
3. **Add read-only agents only where a distinct failure mode exists:**
   - *research/analyst* (before building; judges whether and how — decides the gate memo)
   - *cross-boundary QA* (only if ≥2 services/packages talk to each other over a contract)
   - *security auditor* (if the project takes untrusted input, handles auth, or ships binaries)
   - *compliance auditor* (only if Q7 flagged legal surface — otherwise do not create it)
4. **Tool scoping is part of the definition.** Builders: file tools + shell + doc lookup, no
   messaging/MCP. Auditors and QA: **no `Edit`** — they report, they never fix; their write
   access is limited to their own report path. Every agent file states what to do when a task
   seems to need a missing tool: *stop and report, don't work around it.*
5. **Model tiering** (if Q9 said yes): expensive tier for research, security, compliance,
   planning and the gate; cheap tier for building, QA, live-verify; cheapest for pure lookup
   fan-out. Pin it in each agent's frontmatter so it survives a forgetful operator.

For each agent write down, before drafting the file: its **owned paths**, its **forbidden
paths**, who it may run in parallel with, and the 3–5 conventions it must not violate.

---

## Phase 4 — Write the artifacts

Use `templates/` if you have this directory; otherwise follow the specs below. Fill every
placeholder from the facts table. **Delete any section you cannot ground.**

### `CLAUDE.md` (< ~200 lines)

- **Project overview** — what it is, its components, and the one-paragraph data/control flow.
  Name each component's directory and port/entry point.
- **Hard constraints** — the Q2 answers, one bullet each, each stating *why* if the why is
  non-obvious. Blunt imperatives.
- **Before committing** — the exact gate command, its prerequisites, and whether CI re-checks it.
  If Q4 found tiers, state in bold **what a green fast tier does not prove** and which surfaces
  oblige a local run.
- **Definition of Done** — a checkbox list from Q3.
- **Development** — the 4–6 commands that matter, verbatim. Include how services reload and
  **whether killing/restarting them is safe** — if a watcher rebuilds on save, say "poll for
  readiness, never restart" and give the poll command.
- **Documentation sync** — a two-column table: doc ↔ when it must be updated. Only include docs
  that exist.
- **Harness section** — the agent roster table (agent · tier · role), the routing rule
  (path → agent), the parallel/sequential rule, and where agent memory lives.

Anything longer moves to `docs/` and gets a row in the sync table.

### `.claude/agents/<name>.md`

YAML frontmatter: `name`, `description` (written so a router can match a task to it — name the
trees and the task types), `model`, `tools` (the scoped list). Body:

- **Core role** + owned trees + explicitly forbidden trees.
- **Read first** — an ordered list: `CLAUDE.md`, its own `.claude/agent-memory/<name>/`, the
  hand-off file from the orchestrator. Then *only* the file being changed. State
  "don't re-explore from scratch".
- **Stack** — the frameworks and versions *of its tree*, with the note *verify against the code,
  not memory*.
- **Conventions** — the load-bearing ones only, with file paths.
- **Parallelism rule** — who it may and may not run beside, and why.
- **Output contract** — where it writes its receipt, and that the receipt is terse: what changed,
  where, what the next agent needs to know. Never paste whole files back.
- **When to stop** — missing tool, ambiguous scope, or a constraint conflict → report, don't
  improvise.

### `.claude/skills/<slug>-feature/SKILL.md` (the orchestrator)

Frontmatter `name` + a `description` that lists concrete trigger phrases ("add", "implement",
"fix bug in", "change how X works", plus follow-ups like "redo the API part").

Body, in this order:

1. **What this does** — the pipeline in one line.
2. **Model tiering** — one line per tier.
3. **Execution model** — *the main thread does research-spawn, gate, and final report only.*
   State explicitly that it never edits code, never runs the browser, and never types "just a
   one-line fix" inline — that work is routed to the owning specialist.
4. **Token hygiene** — subagents write detail to a scratch dir (`_workspace/` or similar, add it
   to `.gitignore`) and return a receipt + path. Keep plain prose only for what the human reads:
   the research memo, the security report, the final report.
5. **Phase 0 — context check**: scratch dir exists? partial update → re-run only affected agents;
   new requirements → archive and start fresh.
6. **Phase 1 — research** by the analyst agent; it returns a memo with a
   BUILD / RECONSIDER / NEEDS-INFO verdict; the orchestrator writes it to disk.
7. **Phase 2 — GATE**: summarise the memo, ask go/no-go, and **actually halt**. State that this
   is the last interactive stop and no code is written before it.
8. **Phase 3 — build**: the path→agent routing table, the parallel/sequential rules from Phase 3
   above, the join rule (spawn parallel agents in one message, join all before continuing, one
   retry each on incomplete output, then proceed and note the gap).
9. **Phase 4 — verify**: QA and security (and compliance, *conditionally*) run concurrently
   because they are read-only over the same build. **Then one combined fix loop** — collect the
   union of all findings and re-run the owning specialist once with all of them, not two
   sequential cycles.
10. **Phase 5 — live verify** (only if Q8 said such an environment exists): in a cheap-tier
    subagent that returns PASS/FAIL, never on the main thread.
11. **Phase 6 — regression test**, with **feasibility triage first**: decide *test-required* vs
    *not observable at this layer, cover it one layer down* **before** writing anything. Forbid
    faking an end-to-end test by mocking the very boundary under test; an admitted gap beats a
    vacuous assertion. Forbid conditional assertions (`if (x.length) expect(...)` asserts
    nothing).
12. **Phase 7 — report template** — a fixed markdown skeleton with one line per phase, ending in
    the remaining manual checklist.
13. **Constraints** (copied from `CLAUDE.md`) and **error handling** (missing receipt → read
    source, don't block; conflicting interfaces between agents → surface, don't silently pick).

### `.claude/agent-memory/<agent>/MEMORY.md`

Seed each with an index stub and the rule: *append a one-line entry per finding, link a detail
file, read this before exploring.* Add a `domain_map.md` per builder agent listing its key paths
so the next session skips discovery. Keep entries as durable traps ("X emits Y at time Z —
verified by reading the source"), never as changelog.

### Hooks — `.claude/settings.json` + `scripts/claude-hooks/`

Two hooks, both cheap and both real wins:

- **Output cap** (`PreToolUse`, matcher `Bash`): rewrite known-noisy commands (the test/build
  ones you found) to pipe through `tail -n 250` while preserving the exit code with `pipefail`.
  Skip commands that already filter or redirect. Emit the rewritten command as the hook's
  `updatedInput`.
- **Format on edit** (`PostToolUse`, matcher `Edit|Write`): run the project's actual formatter
  for that file type — only if it is installed; silent on success; **always exit 0** so it can
  never block.

Both read the tool payload as JSON on stdin. Do not add a hook whose formatter this repo does not
have.

### `.claude/rules/response-style.md`

Copy `templates/rules/response-style.md` verbatim unless the human states a different preference.
It carries no project facts. It governs the **structure** of every chat reply — verdict first,
short bullets, caveats never traded away for brevity — and it is the cheapest quality win in the
kit, because a correct answer nobody reads is not delivered.

### `.claude/rules/<env>-sessions.md` — only if Q6 found another environment shape

State the detection condition in the first line (e.g. an env var), then: which `CLAUDE.md`
instructions do **not** apply there, what replaces them, what is unavailable (and that those are
*reportable findings, not workaround targets*), and a triage table of failure → meaning → action
for the failures that have actually happened.

### `docs/harness.md`

What was built, the roster and why those boundaries, the gate and its known gaps, **the open
questions you could not resolve**, and how to extend it. This file is the honest record; the
harness's credibility lives here.

---

## Phase 5 — Verify the harness (do not skip)

1. **Grounding pass.** Re-read your `CLAUDE.md` line by line. For each factual claim, name the
   file you got it from. Anything unsourced: delete it or move it to open questions.
2. **Hook smoke test.** Feed each hook a fake payload and check the output:
   ```bash
   echo '{"tool_input":{"command":"<your test command>"}}' | bash scripts/claude-hooks/<hook>.sh
   echo '{"tool_input":{"file_path":"<a real source file>"}}' | bash scripts/claude-hooks/<hook>.sh
   ```
   Confirm the first emits valid JSON with a wrapped command, the second exits 0 and leaves the
   file valid. A hook that errors breaks every tool call in every future session.
3. **Gate rehearsal.** Run the documented gate command. If it passes, say so. If it fails or
   cannot run here, document the exact failure in `docs/harness.md` — do **not** soften the
   `CLAUDE.md` entry to match your luck.
4. **Roster dry-run.** Take three plausible tasks for this repo and trace each through the
   routing table. If any lands on two agents that both write a collision file, the boundary is
   wrong — fix it now, not after the first parallel run corrupts a file.
5. **Cold-read test.** Ask: could a model with no other context implement a small change here
   using only `CLAUDE.md`? The usual failures are a missing "how do I run it", a missing "how do
   I know it worked", and unstated frozen constraints.
6. **Optional live check.** Spawn one subagent with a small read-only task and confirm it returns
   a terse receipt rather than a wall of file contents. If it returns a wall, the output contract
   in the agent file is not strong enough.

---

## Phase 6 — Report

Commit the harness on its own branch, then report:

- the roster and the one-sentence justification for each boundary,
- the gate, and **exactly what you ran and what you did not**,
- the hard constraints you recorded and who told you,
- the open questions in `docs/harness.md`,
- the first thing to improve after a week of real use (usually: the agent-memory entries, which
  only accumulate by being used).

---

## Anti-patterns — do not produce these

- **An agent per directory.** Ten agents with overlapping writes are strictly worse than two with
  clean boundaries.
- **A `CLAUDE.md` that lists the tech stack and nothing actionable.** The model can read
  `package.json`. It cannot guess the frozen typo or the untriggered CI.
- **Copying another project's conventions** — including this template's example phrasing — where
  you have not verified they hold here.
- **A gate you never ran**, or a Definition of Done listing checks the project does not have.
- **Parallelism without a collision rule.** This corrupts files; it is the most expensive mistake
  in the list.
- **Auditors with `Edit` access.** They start fixing, and nobody reviews the fix.
- **Memory files as changelog.** "Added feature X" is worthless; "the client emits Y before Z,
  which breaks W" is the whole point.
- **A gate at every phase.** One gate, before any code exists. After it, run to completion.
- **Declaring success.** Report what ran, what did not, and what you assumed.
