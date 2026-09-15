# Acceptance checklist for a generated harness

Run this against the harness the probe produced — in the target repo, ideally in a **fresh**
session that did not build it. Every "no" is a defect with a named fix.

## Grounding

- [ ] Every factual claim in `CLAUDE.md` traces to a file in the repo or an interview answer.
- [ ] No framework version, port, path, or command appears that does not exist in the repo.
- [ ] The gate command has actually been run at least once, and `docs/harness.md` records the
      result — including a failure, if it failed.
- [ ] Things that could not be determined are in `docs/harness.md` as open questions, not
      guessed into `CLAUDE.md`.

## Usefulness (the cold-read test)

- [ ] A model with no other context can answer, from `CLAUDE.md` alone: how do I run this? how do
      I know my change works? what must I not break?
- [ ] The hard-constraints section contains at least one thing a competent model would otherwise
      "fix". If it contains none, the interview missed something — ask again.
- [ ] `CLAUDE.md` is under ~200 lines and contains nothing the model could trivially read off a
      manifest.

## Roster

- [ ] Every agent's owned trees are stated, and so are its forbidden trees.
- [ ] No two agents that may run in parallel write the same file. Check against the churn list.
- [ ] Every pair that must be sequential says so **in both agent files and the orchestrator**.
- [ ] Auditor and QA agents have no `Edit` tool.
- [ ] Every agent says what to do when a needed tool is missing (stop and report).
- [ ] Three sample tasks route to exactly one owner each.

## Orchestrator

- [ ] Exactly one interactive gate, before any code is written.
- [ ] The main thread is forbidden from editing code, driving a browser, and inline fixes.
- [ ] Verification agents run concurrently and feed **one** combined fix loop.
- [ ] Test-feasibility triage happens before any test is written, and faking a test by mocking
      the boundary under test is explicitly forbidden.
- [ ] Receipts go to a scratch dir that is git-ignored; the report template is fixed.

## Hooks

- [ ] `echo '{"tool_input":{"command":"<noisy cmd>"}}' | bash <output-cap hook>` emits valid JSON
      with a wrapped command.
- [ ] The same hook exits 0 silently for an unrelated command, and does not double-wrap a command
      that already pipes to `tail`.
- [ ] `echo '{"tool_input":{"file_path":"<real file>"}}' | bash <format hook>` exits 0 and leaves
      the file valid — including when the formatter is not installed.
- [ ] Both hooks are wired in `.claude/settings.json` with `$CLAUDE_PROJECT_DIR`-relative paths.

## Memory

- [ ] Each agent has `.claude/agent-memory/<agent>/MEMORY.md` with the index contract in it.
- [ ] Each builder has a `domain_map.md` listing its key paths.
- [ ] Each agent's "read first" list points at its own memory directory.

## Style

- [ ] `.claude/rules/response-style.md` exists and carries no project-specific facts.

## Honesty

- [ ] The final report names what ran, what did not, and what was assumed.
- [ ] If CI does not verify changes, `CLAUDE.md` says so in bold.
- [ ] If CI is tiered, `CLAUDE.md` names the surfaces the fast tier does not cover, and says who
      runs them.
- [ ] Nothing claims to be verified that was not.
