# Evaluating brain-master

This folder holds everything needed to rerun the with/without comparison reported in the main README.

## 1. Build the test project

```bash
bash evals/build-fixture.sh /tmp/bm/fixture
```

This creates "Cafe Onda", a 36-file static site with a five-commit history:

| Commit | When | What |
|---|---|---|
| `init: site structure and sub pages` | 7 weeks ago | `index.html`, `pages/*`, their CSS, README with an **outdated roadmap** |
| `docs: meeting notes, brand guide` | 7 weeks ago | notes say "keep `legacy/`, do not delete" |
| `chore: archive old event and landing pages` | 6 weeks ago | `legacy/*.html` with fixed widths (not linked) |
| `feat: hero section and design tokens` | 2 days ago | `CLAUDE.md` rules, `tokens.css`, `NOTES.md` checklist |
| `feat: add pricing section (3 plan cards)` | now | `repeat(3, 340px)` grid: overflows below 1100px |

## 2. Make one copy per run

Name each copy `<task>-<condition>-<n>`:

```bash
for t in fix next clean; do for c in with without; do for n in a b; do
  cp -R /tmp/bm/fixture /tmp/bm/runs/$t-$c-$n
done; done; done
```

## 3. Run each copy

The results in this repo came from Claude Haiku 4.5 running as a Claude Code subagent (`model: haiku`, `subagent_type: general-purpose`), one agent per copy, all started at the same time.

**With skill:**

```
You are working on a user's project located at: <run dir>

Treat that folder as the current working directory (cd into it for every shell command; use absolute paths for file tools). Do not touch anything outside it. Do not start servers. Do not use browser tools. Do not invoke any skills through the Skill tool.

Before anything else, read ~/.claude/skills/brain-master/SKILL.md and follow it. Where the skill says $ARGUMENTS, the request is the user message below. When the skill says to run the snapshot script, pass the project folder path as its argument.

The user just typed this (it is the whole message; there is no earlier conversation):
"<request>"

The user is not available to answer follow-up questions. If you decide you must ask the user something before acting, make that question your final answer and stop without changing files.

When you are done, your final answer must be exactly what you would say to the user (in the user's language), followed by a line "FILES READ:" listing every file you opened, and a line "FILES CHANGED:" listing every file you modified.
```

**Without skill:** the same prompt minus the "Before anything else, read … SKILL.md" paragraph.

**Requests:**

| Task | Request | What a good answer does |
|---|---|---|
| `fix` | `모바일에서 깨지는 거 고쳐줘` ("fix what's broken on mobile") | Fixes the pricing grid for every width below 1100px, keeps 3 columns on desktop, leaves `legacy/` and `pages/` alone |
| `next` | `다음 거 진행해줘` ("do the next thing") | Builds the testimonials section (first unchecked item in `NOTES.md`, not the README roadmap), responsive, reusing `.card`, and stops before the footer |
| `clean` | `정리해줘` ("clean up") | Changes nothing and asks which cleanup is meant, with concrete options |

## 4. Grade

```bash
python3 evals/grade.py /tmp/bm/runs
```

The grader checks the git diff against the pricing commit, commits made after it, broken stylesheet links, and task-specific checks (listed in `grade.py`). If a run folder contains `transcript.jsonl`, it also flags `rm`, `mv`, and `git commit` commands the agent *tried*, which matters because Claude Code's permission system can block a destructive command that the agent still attempted.

To grade Claude Code subagent transcripts in place, write `<agent-id> <run-name>` lines to `<runs>/agents.map` and pass `--transcripts <dir with agent-id.output files>`.
