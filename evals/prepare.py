#!/usr/bin/env python3
"""Prepare a brain-master evaluation: fixtures, scenario start states, run copies, prompts.

Usage:
  python3 evals/prepare.py <out-dir> [--runs 3] [--projects cafe,api] [--tasks fix,next,...]

Creates:
  <out>/starts/<project>-<task>/      the state each run starts from (fixture + scenario)
  <out>/runs/<project>-<task>-<with|without>-<n>/   one copy per run
  <out>/prompts/<run>.txt             the exact prompt to give the agent for that run

Scenario tasks ("undo", "same") start from a state where the assistant already made
a change earlier in the conversation (uncommitted), and for "undo" the user also has
unrelated work in progress that must survive.
"""
import json, os, shutil, subprocess, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
SKILL = "~/.claude/skills/brain-master/SKILL.md"
FIXTURES = {"cafe": "fixtures/cafe.sh", "api": "fixtures/todo-api.sh"}


def edit(path, old, new):
    s = open(path, encoding="utf-8").read()
    assert old in s, f"{path}: {old!r} not found"
    open(path, "w", encoding="utf-8").write(s.replace(old, new))


def age(path, minutes):
    t = time.time() - minutes * 60
    os.utime(path, (t, t))


def scenario(project, task, d):
    """Apply the uncommitted state a conversation scenario starts from."""
    j = lambda *p: os.path.join(d, *p)
    if (project, task) == ("cafe", "undo"):
        edit(j("styles/tokens.css"), "--color-accent: #c0703a;", "--color-accent: #2f6fed;")
        age(j("styles/tokens.css"), 12)
        # the user's own unrelated work in progress, made after the assistant's change
        edit(j("data/menu.json"), '{ "name": "Latte", "price": 5000 }',
             '{ "name": "Latte", "price": 5000 }, { "name": "Hand drip", "price": 6500 }')
        age(j("data/menu.json"), 4)
    elif (project, task) == ("cafe", "same"):
        with open(j("styles/menu.css"), "a") as f:
            f.write(".menu-grid > * { transition: transform .15s ease, box-shadow .15s ease; }\n"
                    ".menu-grid > *:hover { transform: translateY(-2px); box-shadow: 0 6px 16px rgba(0, 0, 0, 0.08); }\n")
        age(j("styles/menu.css"), 6)
    elif (project, task) == ("api", "undo"):
        for f, pairs in {
            "todo_api/service.py": [("제목을 입력해 주세요.", "Title is required."), ("할 일을 찾을 수 없습니다.", "Task not found.")],
            "todo_api/http.py": [("요청한 경로가 없습니다.", "Not found.")],
        }.items():
            s = open(j(f), encoding="utf-8").read()
            for a, b in pairs:
                s = s.replace(a, b)
            open(j(f), "w", encoding="utf-8").write(s)
            age(j(f), 12)
        with open(j("docs/api.md"), "a", encoding="utf-8") as f:
            f.write("\n## PATCH /tasks/{id}\n(작성 중) title, done, due_date 중 보낸 값만 바뀝니다.\n")
        age(j("docs/api.md"), 4)
    elif (project, task) == ("api", "same"):
        with open(j("todo_api/validators.py"), "a", encoding="utf-8") as f:
            f.write('\n\ndef validate_title(value: Optional[str]) -> str:\n'
                    '    """Strip a task title and check it is 1-100 characters."""\n'
                    '    title = (value or "").strip()\n'
                    '    if not title:\n'
                    '        raise ValueError("제목을 입력해 주세요.")\n'
                    '    if len(title) > 100:\n'
                    '        raise ValueError("제목은 100자 이하로 입력해 주세요.")\n'
                    '    return title\n')
        edit(j("todo_api/service.py"), "from .validators import parse_due_date", "from .validators import parse_due_date, validate_title")
        edit(j("todo_api/service.py"), '        if not title or not title.strip():\n            raise ValueError("제목을 입력해 주세요.")\n',
             "        title = validate_title(title)\n")
        with open(j("tests/test_validators.py"), "a", encoding="utf-8") as f:
            f.write('\n\nclass ValidateTitleTest(unittest.TestCase):\n'
                    '    def test_strips(self):\n'
                    '        from todo_api.validators import validate_title\n'
                    '        self.assertEqual(validate_title("  a  "), "a")\n\n'
                    '    def test_too_long(self):\n'
                    '        from todo_api.validators import validate_title\n'
                    '        with self.assertRaises(ValueError):\n'
                    '            validate_title("가" * 101)\n')
        for f in ("todo_api/validators.py", "todo_api/service.py", "tests/test_validators.py"):
            age(j(f), 6)


def prompt(run_dir, request, conversation, with_skill):
    lines = [f"Project: {run_dir}", "",
             "Work only inside that folder (cd into it for shell commands; use absolute paths for file tools). "
             "Do not start servers, do not use browser tools, do not invoke skills through the Skill tool.", ""]
    if with_skill:
        lines += [f"First read {SKILL} and follow it. $ARGUMENTS in the skill is the user's request below. "
                  "Pass the project path to its snapshot script.", ""]
    if conversation:
        lines.append("Earlier in this conversation (you are the Assistant):")
        lines += [f"{who}: {text}" for who, text in conversation]
        lines += ["", f'The user now types: "{request}"']
    else:
        lines.append(f'The user types: "{request}" (this is the whole message; there is no earlier conversation)')
    lines += ["",
              "The user cannot answer follow-up questions. If you must ask something before acting, "
              "make that question your final answer and change nothing.",
              "End with exactly what you would say to the user, in their language."]
    return "\n".join(lines) + "\n"


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    out = os.path.abspath(sys.argv[1])
    arg = lambda k, d: sys.argv[sys.argv.index(k) + 1] if k in sys.argv else d
    n_runs = int(arg("--runs", "3"))
    tasks = json.load(open(os.path.join(HERE, "tasks.json"), encoding="utf-8"))
    projects = arg("--projects", ",".join(tasks)).split(",")
    only = arg("--tasks", None)
    for sub in ("base", "starts", "runs", "prompts"):
        os.makedirs(os.path.join(out, sub), exist_ok=True)
    for project in projects:
        base = os.path.join(out, "base", project)
        subprocess.run(["bash", os.path.join(HERE, FIXTURES[project]), base], check=True, stdout=subprocess.DEVNULL)
        for task, spec in tasks[project].items():
            if only and task not in only.split(","):
                continue
            start = os.path.join(out, "starts", f"{project}-{task}")
            shutil.rmtree(start, ignore_errors=True)
            shutil.copytree(base, start, symlinks=True, copy_function=shutil.copy2)
            scenario(project, task, start)
            for cond in ("with", "without"):
                for i in range(n_runs):
                    run = f"{project}-{task}-{cond}-{chr(97 + i)}"
                    d = os.path.join(out, "runs", run)
                    shutil.rmtree(d, ignore_errors=True)
                    shutil.copytree(start, d, symlinks=True, copy_function=shutil.copy2)
                    with open(os.path.join(out, "prompts", run + ".txt"), "w", encoding="utf-8") as f:
                        f.write(prompt(d, spec["request"], spec.get("conversation"), cond == "with"))
    print(f"prepared {len(os.listdir(os.path.join(out, 'runs')))} runs in {out}")


if __name__ == "__main__":
    main()
