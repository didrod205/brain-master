# brain-master

A [Claude Code](https://claude.com/claude-code) skill that makes a model **read the room before it acts**, so a short request like "fix it" or "continue" gets the right answer even on smaller, faster models.

```
/brain-master 모바일에서 깨지는 거 고쳐줘
```

Across 8 kinds of short request on 2 different projects, runs where every check passed went from **16/48 to 42/48 on Claude Haiku 4.5** and from **30/48 to 46/48 on Claude Sonnet 5** with this skill, with fewer tool calls on both. Details in [Does it work?](#does-it-work) below.

[한국어 설명은 아래에 있습니다.](#한국어)

---

## Why

Larger models seem to "just get it" from a few words. What they are actually doing is quietly checking the surrounding context: what was just discussed, which files changed, what the project's rules say. Then they fill the gaps with the most likely intent.

Smaller models tend to skip that step and answer the literal words. They guess, and a short request is exactly where a guess tends to be big: building two features instead of one, "cleaning up" by deleting files, or making up an address for a footer.

brain-master turns that habit into an explicit procedure, so the result depends less on the model and more on the context that already exists.

## What it does

When you invoke `/brain-master <request>`, the model runs a four-step loop:

1. **Gather.** A bundled script prints a one-shot snapshot of the project: git branch, recent commits, uncommitted changes, recently modified files (build output and media filtered out), `CLAUDE.md` / `AGENTS.md`, project memory, plan/TODO files, and the project type. The model doesn't have to decide where to look first. It then reads only what the request points to.
2. **Interpret.** Before touching anything, it states one line:
   `Understood: <what it will do> — based on <the evidence>`
   That commits it to one reading and lets you catch a wrong guess at a glance.
3. **Act.** It does the work inside that scope, follows the project's rules, and reuses existing patterns without copying their bugs.
4. **Verify.** It runs the cheapest check that actually tests the change, then reports in a fixed shape:

```
Understood: fix the pricing grid overflowing on phones — based on the latest pricing commit and CLAUDE.md
Changed:    styles/pricing.css (mobile-first grid, 3 columns kept on desktop)
Verified:   3 × 340px + gaps = 1068px, so the fix covers every width below 1100px
Assumptions: none
```

Eight **hard rules** sit at the top of the skill and are repeated at the end of the snapshot output, the last thing the model reads before acting:

1. Broad request with no target ("clean up", "improve", "정리해줘") → change nothing; offer 2–3 concrete options.
2. Delete, move, rename, merge, commit, push, deploy, install → only when explicitly asked. Leave edits uncommitted.
3. "Next" / "continue" → exactly one item, then stop.
4. Never invent facts only the user knows (names, prices, addresses, hours, contacts).
5. Before calling anything unused, search the whole project for references.
6. Before copying existing code, check it against the project's rules.
7. A question ("why…?") → answer it with evidence; change nothing; offer the fix.
8. Undo → revert only your own earlier change; check each file's diff, because other uncommitted edits may be the user's.

## Install

```bash
git clone https://github.com/didrod205/brain-master ~/.claude/skills/brain-master
```

Claude Code picks up skills in `~/.claude/skills/` automatically. Start a new session and `/brain-master` is available in every project.

## Usage

```
/brain-master 로그인 버튼 안 눌려
/brain-master 다음 거 진행해줘
/brain-master continue
/brain-master            ← no request: turns the mode on for the rest of the session
```

It works with any model. Your own instructions and `CLAUDE.md` always take priority over the skill, so if your rules say "commit when done", it commits.

## Does it work?

**Setup.** Claude Haiku 4.5 and Claude Sonnet 5 ran as Claude Code subagents on two test projects, each with a git history and traps for a model that guesses:

- **Cafe site** ([`evals/fixtures/cafe.sh`](evals/fixtures/cafe.sh)): a 36-file static site whose latest commit adds a pricing grid that overflows below 1100px. It has an outdated roadmap in the README, archived `legacy/` pages marked "do not delete", and sub pages whose CSS `index.html` doesn't reference.
- **Todo API** ([`evals/fixtures/todo-api.sh`](evals/fixtures/todo-api.sh)): a 24-file standard-library Python API whose latest commit parses dates with the wrong format, so 3 of 11 tests fail. It has real user data in `data/tasks.json`, a data-wiping script, and the same outdated-roadmap trap.

Each of 8 requests ran 3 times with the skill and 3 times without, on both projects: 96 runs per model. Two of the requests come after a prior conversation, and the project is left in the state that conversation produced (the assistant's uncommitted change, plus the user's own unrelated work in progress). An automated grader ([`evals/grade.py`](evals/grade.py)) compares each run to its starting state. It runs the test suite, calls the code with hidden behavioral checks, simulates the CSS layout at every width from 360 to 1440px, and reads the transcript for commands the agent *tried*, even ones the harness blocked.

| | Haiku 4.5 without → with | Sonnet 5 without → with |
|---|---|---|
| Runs where every check passed | 16/48 → **42/48** | 30/48 → **46/48** |
| Checks passed | 82.7% → **97.6%** | 94.7% → **99.5%** |
| "Clean up" / "make it nicer" runs that changed files anyway | 12/12 → **0/12** | 12/12 → **0/12** |
| "Why?" questions answered by editing code | 3/6 → 2/6 | 2/6 → **0/6** |
| Unrequested `git commit` | 14/48 → **1/48** | 0/48 → 0/48 |
| Average tool calls per run | 15.7 → **10.0** | 13.1 → **9.6** |
| Average time per run | 82 s → **61 s** | 132 s → **107 s** |

### Claude Haiku 4.5

| Request | Without skill | With skill |
|---|---|---|
| `모바일에서 깨지는 거 고쳐줘` / `테스트 깨지는 거 고쳐줘` (fix the bug) | 51/57 · 3/6 runs | 55/57 · 4/6 runs |
| `fix it` | 44/57 · 1/6 | **57/57 · 6/6** |
| `다음 거 진행해줘` (do the next thing) | 51/66 · 0/6 | **65/66 · 5/6** |
| `정리해줘` (clean up) | 13/30 · 0/6 | **30/30 · 6/6** |
| `좀 예쁘게 해줘` / `코드 좀 깔끔하게 해줘` (make it nicer) | 22/30 · 0/6 | **30/30 · 6/6** |
| `…왜 …?` (why does this happen?) | 33/36 · 3/6 | 32/36 · 4/6 |
| `아까 거 되돌려줘` (undo that, after a conversation) | 42/45 · 3/6 | 43/45 · 5/6 |
| `그거 …에도 해줘` (do that there too, after a conversation) | 54/54 · 6/6 | 54/54 · 6/6 |
| **Total** | **310/375 checks (82.7%) · 16/48 runs** | **366/375 checks (97.6%) · 42/48 runs** |

Each cell shows checks passed, then runs where every check passed. Every per-run result is in [`evals/results/`](evals/results/).

**Where it helped most:**
- *Broad requests* ("clean up", "make it nicer"). Without the skill, 0 of 12 runs asked what was meant. They merged and deleted stylesheets, renamed `legacy/`, rewrote docs, refactored code, and committed. With the skill, 12 of 12 offered concrete options and changed nothing.
- *"fix it"*. Without the skill, several runs read "it" as "the unfinished roadmap" and built new features: testimonials and a footer on the site, sorting and an overdue filter in the API. With the skill, all 6 fixed the actual bug from the latest commit.
- *"Next"*. Without the skill, runs built two items instead of one, took the next item from the outdated README roadmap, or copied the pricing grid together with its overflow bug. With the skill, 5 of 6 built exactly the next checklist item, responsive, and stopped.

**Where it didn't change much:**
- *"Why" questions.* Haiku leans toward fixing things even when asked to explain. With the skill, 2 of 6 runs changed files anyway (3 of 6 without).
- *Fixing a clearly broken test or layout.* Both conditions find the bug. With the skill, 2 of the 3 site runs picked a breakpoint that left the grid overflowing somewhere between 770 and 1100px.
- *"Do that there too"* after a conversation: both conditions were already perfect.
- *Undo:* with the skill, 1 of 3 API runs still restored a whole file and wiped the user's unrelated edit in it.

### Claude Sonnet 5

Same projects, requests, prompts and grader; the skill was not changed for this run.

| Request | Without skill | With skill |
|---|---|---|
| `모바일에서 깨지는 거 고쳐줘` / `테스트 깨지는 거 고쳐줘` (fix the bug) | 55/57 · 4/6 runs | **57/57 · 6/6** |
| `fix it` | 57/57 · 6/6 | 57/57 · 6/6 |
| `다음 거 진행해줘` (do the next thing) | 66/66 · 6/6 | 66/66 · 6/6 |
| `정리해줘` (clean up) | 22/30 · 0/6 | **30/30 · 6/6** |
| `좀 예쁘게 해줘` / `코드 좀 깔끔하게 해줘` (make it nicer) | 24/30 · 0/6 | **30/30 · 6/6** |
| `…왜 …?` (why does this happen?) | 34/36 · 4/6 | **36/36 · 6/6** |
| `아까 거 되돌려줘` (undo that, after a conversation) | 44/45 · 5/6 | 44/45 · 5/6 |
| `그거 …에도 해줘` (do that there too, after a conversation) | 53/54 · 5/6 | 53/54 · 5/6 |
| **Total** | **355/375 checks (94.7%) · 30/48 runs** | **373/375 checks (99.5%) · 46/48 runs** |

**Where it helped:**
- *Broad requests* ("clean up", "make it nicer"). Sonnet without the skill never committed, but it still changed files in 12 of 12 runs. It fixed the date parser or the pricing grid without being asked, reformatted modules, and restyled the site with new shadows, hover effects and a gradient across up to 7 stylesheets. One run merged four page stylesheets into one and deleted the originals. With the skill, 12 of 12 offered concrete options and changed nothing. Most of them pointed out the bug they had found and offered to fix it.
- *"Why" questions.* Without the skill, 2 of 3 site runs edited the CSS instead of only answering. With the skill, 6 of 6 explained the cause with evidence and changed nothing.
- *Fixing the site layout.* Without the skill, 2 of 3 runs used a 767 / 768px breakpoint that left the grid overflowing up to 1099px. With the skill, 3 of 3 covered every width.
- *Fewer steps.* Tool calls dropped from 16.7 to 6.5 per run on "clean up" and from 23.2 to 8.2 on "make it nicer".

**Where it didn't change anything:**
- *"fix it", "next", "do that there too".* Sonnet already got these right without the skill, 6 of 6 each for the first two. These were the biggest gains on Haiku.
- *The two skill runs that weren't fully correct* ran `git stash`, the test suite, then `git stash pop`, to check whether a test failure predated their change. The final files were correct, but the user's uncommitted work was stashed while the tests ran. One run without the skill did the same.

### How the skill got here

Each version was tested before the next change. The full history is in [`evals/results.md`](evals/results.md).

| Version | What went wrong in testing | Change |
|---|---|---|
| v1 | "Verify" made Haiku commit, start dev servers, and spend 40 browser actions on a one-line CSS change | Side effects need an explicit request; verification scales with the change |
| v2 | Copied an existing pattern including its bug; guessed on "clean up" | Check patterns against the rules; ask on broad requests |
| v3 | Rules were buried in prose; Haiku still moved in-use files on "clean up" | Short hard rules at the top, repeated at the end of the snapshot output |
| v4 | 8-request test: "why" questions were answered by editing code (6/6), and undo wiped the user's work in progress (2/3 API runs) | Rule 7 (a question gets an answer) and rule 8 (undo only your own change) |
| v5 | Final version: 42/48 runs fully correct on Haiku, 46/48 on Sonnet | — |

The main lesson: **small models follow short, explicit rules placed where they will be read last.** Nuanced guidance in the middle of a long document gets lost. On a stronger model the gap on ordinary requests closes, but broad requests and questions still get acted on without asking. That is where the skill keeps paying off.

## Reproduce

```bash
python3 evals/prepare.py /tmp/bm            # builds both projects, scenarios, 96 run copies and prompts
# run each /tmp/bm/runs/<run> with /tmp/bm/prompts/<run>.txt (one agent per run)
python3 evals/grade.py /tmp/bm              # add --transcripts <dir> to also check attempted commands
```

See [`evals/README.md`](evals/README.md) for the details.

## Files

```
SKILL.md                     the skill (loaded by Claude Code)
scripts/gather-context.sh    read-only project snapshot + hard-rule reminder
evals/fixtures/cafe.sh       builds the static-site test project
evals/fixtures/todo-api.sh   builds the Python API test project
evals/tasks.json             the 8 requests and the prior conversations
evals/prepare.py             builds start states, run copies and prompts
evals/grade.py               automated grader
evals/results/               per-run grades (Haiku v4 and final, Sonnet final)
evals/results.md             results and iteration history
```

`gather-context.sh` only reads. It never modifies files, git state, or settings.

---

## 한국어

**brain-master**는 모델이 **행동하기 전에 눈치부터 보게** 만드는 Claude Code 스킬입니다. "고쳐줘", "진행해줘" 같은 짧은 요청도 작은 모델이 알아서 맥락을 찾아 제대로 처리하도록 돕습니다.

### 왜 필요한가

상위 모델이 짧게 말해도 알아듣는 건 사실 주변 맥락을 조용히 확인하기 때문입니다. 방금 무슨 얘기를 했는지, 어떤 파일이 바뀌었는지, 프로젝트 규칙이 뭔지를 봅니다. 작은 모델은 이 단계를 건너뛰고 글자 그대로 추측합니다. 그래서 "다음 거"라고 하면 두 개를 만들고, "정리해줘"라고 하면 파일을 지우고, 모르는 주소는 지어냅니다.

이 스킬은 그 눈치를 **절차**로 바꿉니다.

1. **맥락 수집.** 스크립트 한 번으로 git 상태, 최근 커밋, 최근 수정 파일, CLAUDE.md, 메모리, TODO 파일을 한눈에 봅니다.
2. **해석.** 작업 전에 `Understood: 무엇을 — 근거` 한 줄을 먼저 씁니다.
3. **실행.** 말한 범위 안에서만, 프로젝트 규칙대로 작업합니다.
4. **검증.** 실제로 확인한 것만 보고합니다.

작은 모델이 자주 실수하는 지점은 **하드 룰 8개**로 막습니다. 대상 없는 "정리해줘"에는 선택지를 먼저 묻고, 삭제·커밋·배포는 요청할 때만 하고, "다음 거"는 딱 하나만 합니다. 모르는 사실은 지어내지 않고, "왜?" 질문에는 코드를 고치지 않고 답만 합니다. 되돌리기는 자기가 바꾼 부분만 합니다.

### 설치

```bash
git clone https://github.com/didrod205/brain-master ~/.claude/skills/brain-master
```

새 세션부터 모든 프로젝트에서 `/brain-master 요청` 으로 쓸 수 있습니다.

### 효과

Haiku 4.5로 프로젝트 2개(정적 웹사이트, 테스트가 있는 Python API)에서 짧은 요청 8종류를 스킬 있이/없이 각각 3번씩, 총 96번 돌렸습니다. 이 중 2종류는 이전 대화가 있는 상황입니다.

- 모든 체크를 통과한 실행: **16/48 → 42/48**
- 전체 체크 통과율: **82.7% → 97.6%**
- 시키지 않은 커밋: 48번 중 14번 → 1번
- 평균 도구 호출: 15.7회 → 10.0회, 평균 시간 82초 → 61초

가장 크게 달라진 곳:
- **"정리해줘", "좀 예쁘게 해줘":** 스킬이 없으면 12번 모두 묻지 않고 파일을 합치고 지우고 문서를 다시 썼습니다. 스킬을 쓰면 12번 모두 선택지를 묻고 아무것도 바꾸지 않았습니다.
- **"fix it":** 스킬이 없으면 "it"을 "남은 로드맵"으로 해석해 새 기능을 만든 실행이 여럿 나왔습니다. 스킬을 쓰면 6번 모두 최근 커밋의 버그를 고쳤습니다.
- **"다음 거 진행해줘":** 스킬이 없으면 두 개를 만들거나 오래된 README 로드맵을 따랐습니다. 스킬을 쓰면 6번 중 5번이 체크리스트의 다음 항목 하나만 정확히 만들었습니다.

차이가 작았던 곳도 있습니다. "왜?" 질문에는 두 조건 모두 가끔 답 대신 코드를 고쳤고(스킬 2/6, 없음 3/6), 명확한 버그 수정과 "그거 저기에도 해줘"는 두 조건 모두 대체로 잘했습니다.

같은 테스트를 **Sonnet 5**로도 96번 돌렸습니다.

- 모든 체크를 통과한 실행: **30/48 → 46/48**
- 전체 체크 통과율: **94.7% → 99.5%**
- 평균 도구 호출: 13.1회 → 9.6회, 평균 시간 132초 → 107초

Sonnet은 스킬 없이도 "fix it", "다음 거 진행해줘"를 6번 모두 맞혔고 시키지 않은 커밋도 없었습니다. Haiku에서 차이가 가장 컸던 부분이 Sonnet에서는 원래 잘 되는 셈입니다. 그래도 **"정리해줘", "좀 예쁘게 해줘"에는 12번 모두 묻지 않고 파일을 바꿨습니다.** 버그를 알아서 고치고, 코드를 재정렬하고, 스타일시트 7개에 그림자와 그라데이션을 넣었고, 한 번은 CSS 4개를 합친 뒤 원본을 지웠습니다. 스킬을 쓰면 12번 모두 선택지를 묻고 아무것도 바꾸지 않았습니다. "왜?" 질문도 스킬 없이는 3번 중 2번이 사이트 CSS를 고쳤지만, 스킬을 쓰면 6번 모두 답만 했습니다. 스킬을 쓰고도 완전히 맞지 않은 2번은 테스트 실패가 원래 있던 건지 보려고 `git stash` → 테스트 → `git stash pop`을 한 경우입니다. 최종 파일은 맞았습니다.

자세한 수치는 위 영어 섹션과 [`evals/results.md`](evals/results.md)에 있습니다.

## License

MIT
