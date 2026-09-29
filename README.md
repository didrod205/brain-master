# brain-master

A [Claude Code](https://claude.com/claude-code) skill that makes a model **read the room before it acts**, so a short request like "fix it" or "continue" gets the right answer even on smaller, faster models.

```
/brain-master 모바일에서 깨지는 거 고쳐줘
```

On a 36-file test project, Claude Haiku 4.5 went from **76% to 98%** of automated checks passed with this skill. Most of the gain came from ambiguous requests. Details in [Does it work?](#does-it-work) below.

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

Six **hard rules** sit at the top of the skill and are repeated at the end of the snapshot output, the last thing the model reads before acting:

1. Broad request with no target ("clean up", "improve", "정리해줘") → change nothing; offer 2–3 concrete options.
2. Delete, move, rename, merge, commit, push, deploy, install → only when explicitly asked.
3. "Next" / "continue" → exactly one item, then stop.
4. Never invent facts only the user knows (names, prices, addresses, hours, contacts).
5. Before calling anything unused, search the whole project for references.
6. Before copying existing code, check it against the project's rules.

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

It works with any model. The difference is largest with smaller ones (Haiku, or Sonnet at low effort) and on short, context-dependent requests. Your own instructions and `CLAUDE.md` always take priority over the skill. So if your rules say "commit when done", it commits.

## Does it work?

It was tested with a with/without comparison in the style of an A/B test.

**Setup.** Claude Haiku 4.5 ran as a Claude Code subagent on a 36-file static site with a git history ([`evals/build-fixture.sh`](evals/build-fixture.sh)). The latest commit adds a pricing grid that overflows on phones. The project also contains traps: an outdated roadmap in the README, archived `legacy/` pages marked "do not delete", and sub pages whose CSS `index.html` doesn't reference. Each request was run twice with the skill and twice without, and graded by an automated script ([`evals/grade.py`](evals/grade.py)) that also reads transcripts. That way it catches destructive commands the agent *tried*, even when the harness blocked them.

| Request | Without skill | With skill |
|---|---|---|
| `모바일에서 깨지는 거 고쳐줘` (fix what's broken on mobile) | 21/22 (95%) | 21/22 (95%) |
| `다음 거 진행해줘` (do the next thing) | 19/26 (73%) | **26/26 (100%)** |
| `정리해줘` (clean up) | 7/14 (50%) | **14/14 (100%)** |
| **Total** | **47/62 (76%)** | **61/62 (98%)** |
| Avg. tool calls per run | 21.2 | 10.8 |

**What changed with the skill:**
- *"Next."* Without the skill, Haiku built the footer as well in both runs and invented an address, opening hours, a phone number, and an email. With it, both runs built exactly the next unchecked item and stopped.
- *"Clean up."* Without the skill, one run rewrote 7 docs, created 4 new ones, and committed. Another merged five stylesheets into one and deleted the originals. In an earlier round, a run ran `rm -rf legacy/` and was stopped only by the permission system. With the final skill, both runs changed nothing and asked the user to pick from concrete options.
- *Plain bug fix.* No difference. Both conditions found the bug. One run in each condition picked a breakpoint that still left the grid overflowing somewhere between 768 and 1100px.

**Limitations.** Two runs per condition on one project is a small sample, so read these results as directional. The subagents had no conversation history, so this tests context taken from the project, not from the chat. `정리해줘` is listed by name in the hard rules, so the clean-up test is not a pure generalization test. The skill's examples deliberately use unrelated scenarios (a login button, an API step, a deploy) so they don't leak test answers.

### How the skill got here

The first version didn't beat the baseline. The full history is in [`evals/results.md`](evals/results.md); here is the short version:

| Version | What went wrong | Fix |
|---|---|---|
| v1 | "Verify" made Haiku commit on its own, start dev servers, and spend 40 browser actions on a one-line CSS change | Side effects need an explicit request; verification scales with the change |
| v2 | Reused an existing pattern *including its bug*, and guessed on "clean up" | Check patterns against the rules; ask on broad requests |
| v3 | Rules existed but were buried in prose; Haiku still moved in-use files on "clean up" (53/62) | Short **hard rules at the top**, **repeated at the end of the snapshot output** |
| v4 | 61/62 | — |

The main lesson: **small models follow short, explicit rules placed where they will be read last.** Nuanced guidance in the middle of a long document gets lost.

## Reproduce

```bash
bash evals/build-fixture.sh /tmp/bm/fixture
# copy it once per run: /tmp/bm/runs/fix-with-a, fix-without-a, next-with-a, …
# run each with the prompts in evals/README.md, then:
python3 evals/grade.py /tmp/bm/runs
```

See [`evals/README.md`](evals/README.md) for the exact prompts and the checks.

## Files

```
SKILL.md                    the skill (loaded by Claude Code)
scripts/gather-context.sh   read-only project snapshot + hard-rule reminder
evals/build-fixture.sh      builds the test project
evals/grade.py              automated grader (diffs, git history, transcripts)
evals/README.md             prompts and how to run the evaluation
evals/results.md            per-run results and iteration history
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

그리고 작은 모델이 자주 실수하는 지점을 **하드 룰 6개**로 막습니다. 대상 없는 "정리해줘"에는 선택지를 먼저 묻고, 삭제·커밋·배포는 요청할 때만 하고, "다음 거"는 딱 하나만 하고, 모르는 사실은 지어내지 않습니다.

### 설치

```bash
git clone https://github.com/didrod205/brain-master ~/.claude/skills/brain-master
```

새 세션부터 모든 프로젝트에서 `/brain-master 요청` 으로 쓸 수 있습니다.

### 효과

Haiku 4.5로 같은 프로젝트, 같은 요청을 스킬 있이/없이 비교했습니다.

- 전체 체크 통과율: **76% → 98%**
- "다음 거 진행해줘": 73% → 100%. 스킬 없이는 두 번 모두 푸터까지 만들고 주소·영업시간을 지어냈습니다.
- "정리해줘": 50% → 100%. 스킬 없이는 문서 11개를 고치거나 CSS를 합치고 삭제했고, 이전 라운드에서는 `rm -rf legacy/`를 시도하기도 했습니다. 스킬을 쓰면 두 번 모두 아무것도 바꾸지 않고 선택지를 물었습니다.
- 단순 버그 수정: 차이 없음 (95% vs 95%)

표본이 작다는 점(조건당 2회, 프로젝트 1개)은 감안해 주세요. 자세한 내용은 위 영어 섹션과 [`evals/results.md`](evals/results.md)에 있습니다.

## License

MIT
