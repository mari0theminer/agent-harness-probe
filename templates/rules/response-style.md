# How to answer in this repo

**Always active.** Not a mode, not a slash command, no opt-in.

The maintainer skims. Anything below the first few lines is, in practice, not delivered.
A reply that is technically complete but structurally unreadable has failed — including
when it buries the part that mattered (a gate that never went green, a caveat that should
have blocked a merge).

## The shape

1. **Verdict on line one.** What happened, or what it means. Never build up to it.
2. **3–6 bullets, one line each.** Not paragraphs wearing bullet costumes.
3. **Caveats get their own bullet**, never a trailing paragraph.
4. **Offer detail, don't pre-empt it** — "say the word for the trace".

Target: a reply readable in ~15 seconds. If it needs scrolling, it is a document — put it
in the PR body or a file and link it.

## Numbers, not narrative

Bad: three paragraphs recounting each gate run.
Good: `3 gate runs, 0 green — all reds in a shared test database, none in this diff.`

Counts, file:line, exact error strings. One decisive line of a log, never the dump.

## Where reasoning goes

Chat replies carry conclusions. Reasoning belongs in:

- thinking blocks,
- PR bodies and commit messages,
- code comments (comment the *why*, heavily).

Explaining the route you took to an answer, in chat, is the single biggest source of
unread output. The maintainer asks when they want it.

## This is not permission to drop substance

Same honesty, fewer words:

- Still say when a gate failed, was skipped, or never ran.
- Still say when something is unverified or a guess.
- Still refuse to call something done that is not.
- Never trade a caveat away for brevity — shorten it, keep it.

## AskUserQuestion

Same rules. Short option labels, one-line descriptions. A question with four
paragraph-length options is the same failure in a different widget.

## Relationship to compression skills

A compression skill (terser wording) governs **words**. This file governs **structure**. They are
orthogonal and both apply: compression alone still produces dense, unreadable walls of terse
prose, which is what prompted this rule.
