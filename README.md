# agent-harness-probe

**Build a serious Claude Code agent harness in a repo the model knows nothing about.**

This is one prompt. You paste it into a fresh session in *your* repo, it reads the code, asks you
the handful of things code cannot answer, and writes a harness derived from **your** project's
real structure — not from assumptions and not from a template someone else's stack shaped.

No install. No dependency. No framework.

> **Status — honest about its own coverage, as it asks you to be.** This kit was extracted from
> a harness that works in one repo. It has not yet been run end-to-end against an unrelated one.
> If you try it, the result of `CHECKLIST.md` is the most useful bug report you can file.

---

## Use it

1. Open a **fresh** Claude Code session in your repo. No prior context — that is the point.
2. Paste the full contents of [`PROBE.md`](PROBE.md) as the first message. Nothing else.
3. Answer the interview in Phase 2. It is short, and every question is one the code cannot
   answer for itself.
4. Review the generated `CLAUDE.md` and agent roster before your first real feature run.

If you cloned this repo next to your project instead, just say:
`Follow agent-harness-probe/PROBE.md.`

Then grade the result with [`CHECKLIST.md`](CHECKLIST.md) — ideally in a *second* fresh session
that did not build it. Every "no" is a defect with a named fix.

---

## What you get

In your repo:

```
CLAUDE.md                          # project memory: architecture, hard constraints, DoD, gate
.claude/settings.json              # hooks wiring (+ MCP enablement if any)
.claude/agents/*.md                # roster derived from write-ownership boundaries
.claude/skills/<slug>-feature/     # the orchestrator: research → gate → build → verify → report
.claude/agent-memory/<agent>/MEMORY.md
.claude/rules/response-style.md    # how replies are structured
.claude/rules/<env>-sessions.md    # only if a second environment shape exists
scripts/claude-hooks/*.sh          # output cap + format-on-edit
docs/harness.md                    # what was built, what was assumed, what is still open
```

---

## What's in here

| File | What it is |
|---|---|
| [`PROBE.md`](PROBE.md) | The prompt. Six phases: recon → interview → derive roster → write → verify → report. |
| [`BLUEPRINT.md`](BLUEPRINT.md) | The *why*. Nine principles the probe enforces. Read this to adapt the probe rather than run it. |
| [`CHECKLIST.md`](CHECKLIST.md) | Acceptance criteria for the generated harness. |
| [`templates/`](templates) | File skeletons the probe fills in — a starting shape, not a contract. |

---

## What it deliberately does not do

- **It does not invent conventions.** Anything it could not discover or ask about goes into
  `docs/harness.md` as an open question, never guessed into `CLAUDE.md`.
- **It does not create an agent per directory.** Agents come from **non-overlapping write
  boundaries**. A repo with one real tree gets one builder, and that is the correct answer.
- **It does not claim a gate passed.** It runs what it can, reports what it could not, and never
  writes a Definition of Done it has not seen succeed at least once.

---

## Origin

Extracted from a working harness on a multi-service streaming platform (TypeScript SPA, several
Go services, a native Android client). The principles are the transferable part; the worked
examples in `BLUEPRINT.md` are labelled **[origin]** and are illustrations, not requirements.

## License

MIT — see [`LICENSE`](LICENSE).
