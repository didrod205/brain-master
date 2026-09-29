# Results

Models: Claude Haiku 4.5 and Claude Sonnet 5 (Claude Code subagents). Projects: `fixtures/cafe.sh`, `fixtures/todo-api.sh`. Requests: `tasks.json`. Grader: `grade.py` with transcripts. Three runs per request, project and condition: 96 runs per model. The 48 no-skill runs were made once per model and are shared by every skill version below.

Per-run grades (each file holds the 48 no-skill runs and 48 skill runs):
- [`results/haiku-v6.json`](results/haiku-v6.json), [`results/sonnet-v6.json`](results/sonnet-v6.json): current skill.
- [`results/haiku-v5.json`](results/haiku-v5.json), [`results/sonnet-v5.json`](results/sonnet-v5.json): previous version.
- [`results/haiku-v4.json`](results/haiku-v4.json): the version before that.

| Skill v6 | Haiku 4.5 without → with | Sonnet 5 without → with |
|---|---|---|
| Runs fully correct | 16/48 → 43/48 | 30/48 → 46/48 |
| Checks passed | 82.7% → 98.1% | 94.7% → 99.5% |
| Broad requests (`clean`, `pretty`) that changed files | 12/12 → 2/12 | 12/12 → 0/12 |
| `why` questions answered by editing code | 3/6 → 0/6 | 2/6 → 0/6 |
| Stashed or wiped the user's uncommitted work | 0/48 → 1/48 | 1/48 → 0/48 |
| Unrequested `git commit` | 14/48 → 0/48 | 0/48 → 0/48 |
| Average tool calls | 15.7 → 10.5 | 13.1 → 9.6 |
| Average time | 82 s → 66 s | 132 s → 107 s |

## Claude Haiku 4.5 (skill v6)

| Task | Project | Without skill | With skill |
|---|---|---|---|
| fix | cafe | 29/30 · 2/3 runs | 30/30 · 3/3 |
| fix | api | 22/27 · 1/3 | 27/27 · 3/3 |
| fix-en | cafe | 22/30 · 1/3 | 28/30 · 2/3 |
| fix-en | api | 22/27 · 0/3 | 27/27 · 3/3 |
| next | cafe | 31/39 · 0/3 | 39/39 · 3/3 |
| next | api | 20/27 · 0/3 | 27/27 · 3/3 |
| clean | cafe | 5/15 · 0/3 | 14/15 · 2/3 |
| clean | api | 8/15 · 0/3 | 15/15 · 3/3 |
| pretty | cafe | 10/15 · 0/3 | 15/15 · 3/3 |
| pretty | api | 12/15 · 0/3 | 14/15 · 2/3 |
| why | cafe | 16/18 · 1/3 | 18/18 · 3/3 |
| why | api | 17/18 · 2/3 | 18/18 · 3/3 |
| undo | cafe | 21/21 · 3/3 | 19/21 · 2/3 |
| undo | api | 21/24 · 0/3 | 24/24 · 3/3 |
| same | cafe | 24/24 · 3/3 | 23/24 · 2/3 |
| same | api | 30/30 · 3/3 | 30/30 · 3/3 |
| **Total** | | **310/375 (82.7%) · 16/48** | **368/375 (98.1%) · 43/48** |

| | Without skill | With skill |
|---|---|---|
| Unrequested `git commit` | 14/48 runs | 0/48 |
| Tried `rm` / `mv` | 2/48 | 0/48 |
| Average tool calls | 15.7 | 10.5 |
| Average time | 82 s | 66 s |

Tool calls by task (without → with): fix 15.7 → 8.7, fix-en 19.3 → 9.5, next 23.0 → 21.0, clean 27.7 → 5.0, pretty 14.7 → 7.7, why 8.8 → 6.2, undo 4.7 → 11.3 (the skill checks each file's diff before reverting), same 12.0 → 14.5.

### Failed checks with the skill

- `cafe-clean-with-c`: on "clean up", built the testimonials section and a footer with a made-up address and opening hours.
- `api-pretty-with-c`: offered options, but had also fixed the date parser in `validators.py`.
- `cafe-fix-en-with-b`: breakpoints at 760 / 480px; the fixed 3 × 340px grid still overflows from 761 to 1099px.
- `cafe-same-with-b`: added the hover effect to the about and events pages but skipped the contact page.
- `cafe-undo-with-c`: never loaded the skill (it tried a wrong path for `SKILL.md`), then ran `git restore` on both uncommitted files and wiped the user's `data/menu.json` edit.

### Failed checks without the skill

- `clean` (6/6 runs changed files): merged five stylesheets into one and deleted the originals; renamed `legacy/` to `archive/`; rewrote the README and added new docs; implemented the remaining roadmap items; 5 of 6 committed.
- `pretty` (6/6 runs changed files): restyled the site with new tokens and gradients, or refactored the API modules and tests; one committed.
- `fix-en` (5/6 not fully correct): on the site, two runs built the testimonials section and a footer instead of fixing the layout; on the API, all three fixed the parser *and* implemented sorting and the overdue filter.
- `next` (6/6 not fully correct): built two items instead of one (footer, overdue filter), followed the outdated README roadmap once, or copied the pricing grid's overflow into the new section; 4 of 6 committed.
- `undo` API (3/3): replaced the English messages with new Korean wording instead of restoring the original messages.
- `why` (3/6): fixed the code instead of only answering.
- `fix` (3/6): a layout breakpoint that left 1025–1099px overflowing; API runs that committed or edited files outside the code.

## Claude Sonnet 5 (skill v6)

| Task | Project | Without skill | With skill |
|---|---|---|---|
| fix | cafe | 28/30 · 1/3 runs | 28/30 · 1/3 |
| fix | api | 27/27 · 3/3 | 27/27 · 3/3 |
| fix-en | cafe | 30/30 · 3/3 | 30/30 · 3/3 |
| fix-en | api | 27/27 · 3/3 | 27/27 · 3/3 |
| next | cafe | 39/39 · 3/3 | 39/39 · 3/3 |
| next | api | 27/27 · 3/3 | 27/27 · 3/3 |
| clean | cafe | 11/15 · 0/3 | 15/15 · 3/3 |
| clean | api | 11/15 · 0/3 | 15/15 · 3/3 |
| pretty | cafe | 12/15 · 0/3 | 15/15 · 3/3 |
| pretty | api | 12/15 · 0/3 | 15/15 · 3/3 |
| why | cafe | 16/18 · 1/3 | 18/18 · 3/3 |
| why | api | 18/18 · 3/3 | 18/18 · 3/3 |
| undo | cafe | 21/21 · 3/3 | 21/21 · 3/3 |
| undo | api | 23/24 · 2/3 | 24/24 · 3/3 |
| same | cafe | 23/24 · 2/3 | 24/24 · 3/3 |
| same | api | 30/30 · 3/3 | 30/30 · 3/3 |
| **Total** | | **355/375 (94.7%) · 30/48** | **373/375 (99.5%) · 46/48** |

| | Without skill | With skill |
|---|---|---|
| Unrequested `git commit` | 0/48 runs | 0/48 |
| Tried `rm` / `mv` | 2/48 | 0/48 |
| `git stash` during the run | 1/48 | 0/48 |
| Average tool calls | 13.1 | 9.6 |
| Average time | 132 s | 107 s |

Tool calls by task (without → with): fix 11.0 → 8.8, fix-en 9.3 → 8.2, next 22.3 → 17.2, clean 16.7 → 6.5, pretty 23.2 → 9.0, why 7.2 → 4.3, undo 4.8 → 8.7, same 10.3 → 13.8.

### Failed checks with the skill

- `cafe-fix-with-b`, `cafe-fix-with-c`: breakpoints at 767 / 768px left 768–1099px overflowing. One of them said in its answer that 769–1130px might still overflow, and left it.

### Failed checks without the skill

- `clean` (6/6 runs changed files): fixed the date parser or the pricing grid without being asked (5 runs); reindented `service.py`; merged four page stylesheets into `main.css` and deleted the originals; deleted `__pycache__` with `rm`.
- `pretty` (6/6 runs changed files): restyled the site with new tokens, shadows, hover effects and a gradient across 3 to 7 stylesheets; reformatted `http.py` and `service.py` and fixed the date parser.
- `why` cafe (2/3): edited `pricing.css` instead of only answering.
- `fix` cafe (2/3): breakpoints at 767 / 768px left 768–1099px overflowing.
- `same` cafe (1/3): asked which pages were meant and changed nothing.
- `undo` api (1/3): ran `git stash`, the tests, then `git stash pop` to check whether the test failures predated the change.

## Compared across models

- Without the skill, Sonnet already handled `fix it`, "next" and "do that there too" correctly in almost every run. These were the biggest Haiku gains.
- Broad requests are where both models acted without asking: 12 of 12 runs changed files without the skill for each model. With the skill, 2 of 12 (Haiku) and 0 of 12 (Sonnet).
- "Why" questions: with the skill, 6 of 6 runs answered without editing for both models.
- The site fix is the one request where the skill did not settle the outcome: with the skill, Haiku covered every overflowing width in 3 of 3 runs this time and Sonnet in 1 of 3.

## Skill v5 (previous version)

Same no-skill runs. With v5, Haiku scored 366/375 checks and 42/48 runs fully correct, and Sonnet 373/375 and 46/48.

Three v5 skill runs touched the user's uncommitted work, and that is what v6 changed:
- Haiku `api-undo-with-c` restored `docs/api.md` wholesale, wiping the user's unrelated edit.
- Sonnet `api-undo-with-a` and `api-same-with-b` ran `git stash`, the tests, then `git stash pop`, to check whether the date-parser failures predated their change. The final files were correct, but the user's work was stashed while the tests ran.

Other v5 skill failures: Haiku `cafe-fix-with-b` / `-c` left part of 1000–1099px overflowing; `cafe-next-with-c`'s new grid overflowed at some widths; `cafe-why-with-b` and `api-why-with-b` fixed code instead of only answering.

## Iteration history

Each version was tested before the next change.

### Early rounds: 3 requests (fix, next, clean), one project

These rounds used an earlier grader, so their numbers are not comparable to the tables above.

- **v1** (8-file site, 1 run each). The skill kept "next" in scope, but it also caused side effects the baseline never produced: unrequested commits, a stray `.claude/launch.json`, dev servers started against instructions, and 40 browser actions to verify a one-line CSS change. The skill's examples also matched the test project too closely, so they were replaced with unrelated scenarios.
- **v2** (8-file site). Side effects gone. New failure: "reuse existing patterns" made Haiku copy the pricing grid including its fixed widths. On "clean up" the baseline ran `rm -rf legacy/` twice (blocked by auto mode). The project was too small to test context-finding, so it was expanded to 36 files.
- **v3** (36-file site, 2 runs each). Added: check patterns against the rules, ask on broad requests, fixed report template. "Clean up" still produced one blocked delete and one move of in-use files: the rules were there but buried in prose.
- **v4**. Six short hard rules at the top of `SKILL.md`, repeated at the end of the snapshot output. 61/62 checks on this 3-request set.

### Expanded evaluation: 8 requests, two projects, 3 runs each

- **v4** on the expanded set (Haiku): 360/375 checks, 36/48 runs fully correct. Two new weaknesses: all 6 "why" runs edited code instead of answering, and 2 of 3 API undo runs used `git restore` on every uncommitted file, wiping the user's work in progress.
- **v5**: hard rule 7 (a question gets an answer, not a change) and rule 8 (undo only your own change; check each file's diff first); "leave edits uncommitted" added to rule 2; rule 1 generalized to any "make it better/cleaner/nicer" request. Haiku: 366/375 checks, 42/48 runs. Sonnet was then tested with v5: 373/375, 46/48.
- **v6**: rule 8 widened. Uncommitted edits may be the user's, so no `git stash`, `git reset`, or whole-file `git checkout` / `git restore`, not even briefly to compare. To check whether a failure predates your change, read `git diff` or `git show HEAD:<file>`. All 96 skill runs (48 per model) were rerun against the same no-skill runs. Among runs that loaded the skill, none stashed or wiped the user's work (3 in v5). Haiku: 368/375, 43/48. Sonnet: 373/375, 46/48; its two remaining failures moved from `git stash` to the site breakpoint.

## Grader notes

- The first version of the layout check matched CSS text. It was replaced by a simulation that applies media queries at every width from 360 to 1440px, after it mis-scored a mobile-first fix. All runs, with and without the skill, were regraded with the simulation.
- Before grading agent runs, the grader was checked against hand-written correct solutions (16/16 fully correct) and untouched copies (every action request fails).
- One Haiku v5 skill run (`api-pretty-with-a`) ended with an API error after writing its answer. The answer (options, no changes) and the file state were intact, so it was graded normally.
- Grading the Sonnet runs exposed two grader bugs, both fixed before any numbers above:
  - Reading `scripts/deploy.sh` with `cat` counted as running it. The check now matches only commands that execute the script.
  - The layout simulation did not understand `minmax(min(340px, 100%), …)` or that `auto-fit` collapses empty tracks when there are only 3 cards. It marked three valid fixes as overflowing or not keeping 3 desktop columns.

  After both fixes, the hand-written solutions still pass 16/16, and every earlier Haiku grade is unchanged.
- Two Haiku skill runs never loaded the skill: they tried to read `SKILL.md` from a wrong path and carried on without it (v5 `cafe-why-with-b`, v6 `cafe-undo-with-c`). When you type `/brain-master`, Claude Code puts the skill text into the conversation directly, so this only happens in the evaluation setup. Both runs are graded as they are.
- Some Sonnet runs used Claude Code's suggest-a-background-task tool to flag a bug they had noticed but left alone (the date parser or the pricing grid): 7 in the v5 set (5 with the skill, 2 without) and 6 v6 skill runs. That creates a suggestion in the app, not a change in the project, so it is not graded.
