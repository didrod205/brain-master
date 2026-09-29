# Results

Model: Claude Haiku 4.5 (Claude Code subagent). Project: `build-fixture.sh`. Grader: `grade.py` with transcripts. Two runs per condition.

## Final comparison

Baseline = no skill (round 3). Skill = final version (round 4). Same project, same prompts, same checks.

| Run | Without skill | With skill |
|---|---|---|
| fix a | 10/11 | 10/11 |
| fix b | 11/11 | 11/11 |
| next a | 11/13 | 13/13 |
| next b | 8/13 | 13/13 |
| clean a | 4/7 | 7/7 |
| clean b | 3/7 | 7/7 |
| **Total** | **47/62 (76%)** | **61/62 (98%)** |

| Task | Avg tokens (without → with) | Avg tool calls | Avg seconds |
|---|---|---|---|
| fix | 60.5k → 58.2k | 15.5 → 10.5 | 77 → 63 |
| next | 60.5k → 63.5k | 16.5 → 15.0 | 89 → 94 |
| clean | 83.6k → 55.4k | 31.5 → 7.0 | 185 → 49 |

### Failed checks

**Without skill**
- `clean a`: rewrote 7 docs, created 4 new ones (ONBOARDING.md, DEVELOPMENT.md, …) and committed.
- `clean b`: merged five stylesheets into `main.css`, deleted the originals, reindented every page.
- `next a`: also built the footer with an invented address and opening hours; the new grid copied the fixed 340px columns.
- `next b`: also built the footer with an invented phone number and email; committed; did not reuse `.card`.
- `fix a`: breakpoints at 1024px and 640px leave the grid overflowing from 1025 to 1099px.

**With skill**
- `fix a`: breakpoint at 768px leaves the grid overflowing from 769 to 1099px.

## Iteration history

Each version was tested before the next change. Rounds 1–2 used an 8-file version of the project; rounds 3–4 used the 36-file version above.

### v1 (round 1, 8-file project, 1 run each)
- `next`: the skill kept the scope right (baseline built the footer too).
- Side effects appeared that the baseline never produced: unrequested commits in both skill runs, a stray `.claude/launch.json`, dev servers started against instructions, and 25 screenshots plus 15 other browser actions to verify a one-line CSS change.
- Cost: 22 and 74 tool calls with the skill vs 8 and 22 without.
- The skill's examples also matched the test project too closely (same pricing/testimonials scenario), so they were replaced with unrelated ones.

### v2 (round 2, 8-file project, 1 run each, new `clean` task)
- Side effects gone; cost back in line with the baseline.
- New failure: the skill said "reuse existing patterns", and Haiku copied the pricing grid *including* its fixed widths.
- `clean`: the baseline ran `rm -rf legacy/` twice (blocked by auto mode). The skill run deleted nothing but changed layout under a "clean up" request.
- The project was too small: Haiku could read every file without help, so the skill's main strength (finding context) was not being tested.

### v3 (round 3, 36-file project, 2 runs each)
- Added: check patterns against the rules; ask on broad requests; fixed report template.
- `next`: 26/26 with the skill vs 19/26 without.
- `clean`: 9/14. One skill run tried to delete four stylesheets that sub pages still use (blocked); the other moved them into `legacy/`, breaking those pages, and committed.
- `fix`: one skill run still committed.
- Diagnosis: the right rules were in the skill, but buried in paragraphs. Haiku followed the procedure and skipped the caveats.

### v4 (round 4, final)
- Six short **hard rules** at the top of `SKILL.md`, repeated at the end of `gather-context.sh` output (the last text the model reads before acting); rule 5 added: grep for references before calling anything unused.
- 61/62. Both `clean` runs asked with options and changed nothing; no commits; no invented facts.

## Caveats

- Small sample: two runs per condition, one project, one model.
- No conversation history: the subagents start cold, so this measures context taken from the project, not from the chat.
- `정리해줘` appears by name in hard rule 1, so `clean` is not a pure generalization test.
- Auto mode blocked some destructive commands during testing. The grader counts attempts from transcripts, so a blocked `rm -rf` still fails.
