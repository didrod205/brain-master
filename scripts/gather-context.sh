#!/usr/bin/env bash
# brain-master: print a compact, read-only snapshot of the context around a request,
# so the model does not have to decide where to look first.
# Usage: gather-context.sh [project-dir]   (defaults to the current directory)
# This script only reads. It never modifies files, git state, or settings.

dir="${1:-$PWD}"
cd "$dir" 2>/dev/null || { echo "gather-context: cannot enter $dir"; exit 1; }

section() { printf '\n## %s\n' "$1"; }

# show FILE [MAXLINES] - print the head of a file and note how much was cut.
show() {
  local f="$1" n="${2:-40}" total
  total=$(wc -l < "$f" | tr -d ' ')
  sed -n "1,${n}p" "$f"
  if [ "$total" -gt "$n" ]; then echo "... ($((total - n)) more lines in $(short "$f"))"; fi
}

# short PATH - print a path relative to the project root, or with ~ for home.
short() {
  case "$1" in
    "$root"/*) printf '%s' "${1#"$root"/}" ;;
    "$HOME"/*) printf '~/%s' "${1#"$HOME"/}" ;;
    *) printf '%s' "$1" ;;
  esac
}

echo "# brain-master context snapshot"
echo "time: $(date '+%Y-%m-%d %H:%M %Z')"
echo "dir:  $PWD"
root="$PWD"

section "Git"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  root=$(git rev-parse --show-toplevel)
  echo "root:   $root"
  branch=$(git branch --show-current 2>/dev/null)
  echo "branch: ${branch:-(detached)}"
  echo "recent commits:"
  git log -8 --pretty=format:'  %h %ar  %s' 2>/dev/null
  echo
  changes=$(git status --short 2>/dev/null)
  if [ -n "$changes" ]; then
    n=$(printf '%s\n' "$changes" | wc -l | tr -d ' ')
    echo "uncommitted changes ($n):"
    printf '%s\n' "$changes" | head -25 | sed 's/^/  /'
    if [ "$n" -gt 25 ]; then echo "  ... ($((n - 25)) more)"; fi
    stat=$(git diff --stat HEAD 2>/dev/null | tail -12)
    if [ -n "$stat" ]; then echo "diff stat vs HEAD:"; printf '%s\n' "$stat" | sed 's/^/  /'; fi
  else
    echo "working tree clean"
  fi
else
  root="$PWD"
  echo "not a git repository"
fi

section "Recently modified files (last 3 days, newest first)"
# Skip dependency/build folders and media/binary files: a single build or image
# export can touch hundreds of files and bury the hand-edited source files.
recent=$(find . \( -name node_modules -o -name .git -o -name dist -o -name build -o -name out \
  -o -name .next -o -name .turbo -o -name .vercel -o -name .output -o -name target \
  -o -name .venv -o -name venv -o -name __pycache__ -o -name .cache -o -name coverage \
  -o -name Pods -o -name DerivedData -o -name vendor -o -name _next \) -prune \
  -o -type f -mmin -4320 \
  ! -name .DS_Store ! -name '*.lock' ! -name 'package-lock.json' ! -name '*.map' ! -name '*.min.*' ! -iname '*.svg' \
  ! -iname '*.png' ! -iname '*.jpg' ! -iname '*.jpeg' ! -iname '*.gif' ! -iname '*.webp' \
  ! -iname '*.avif' ! -iname '*.ico' ! -iname '*.mp4' ! -iname '*.mov' ! -iname '*.pdf' \
  ! -iname '*.woff' ! -iname '*.woff2' ! -iname '*.ttf' ! -iname '*.otf' ! -iname '*.zip' \
  -print 2>/dev/null | head -300)
if [ -n "$recent" ]; then
  sorted=$(printf '%s\n' "$recent" | tr '\n' '\0' | xargs -0 ls -dt 2>/dev/null)
  printf '%s\n' "$sorted" | head -15 | sed 's/^/  /'
  n=$(printf '%s\n' "$sorted" | wc -l | tr -d ' ')
  if [ "$n" -gt 15 ]; then
    echo "most active folders ($n files changed):"
    printf '%s\n' "$sorted" | sed 's|^\./||; s|/[^/]*$||' | cut -d/ -f1-3 \
      | sort | uniq -c | sort -rn | head -6 | sed 's/^ */  /'
  fi
else
  echo "  (none)"
fi

section "Standing instructions (these override defaults)"
seen=""
found=0
for f in "$PWD/CLAUDE.md" "$root/CLAUDE.md" "$root/.claude/CLAUDE.md" "$root/AGENTS.md" "$HOME/.claude/CLAUDE.md"; do
  [ -f "$f" ] || continue
  case "$seen" in *"|$f|"*) continue ;; esac
  seen="$seen|$f|"
  found=1
  echo "### $(short "$f")"
  show "$f" 40
done
[ "$found" -eq 0 ] && echo "  (no CLAUDE.md / AGENTS.md found)"

section "Memory index"
seen=""
found=0
for d in "$PWD" "$root"; do
  slug=$(printf '%s' "$d" | sed 's/[^A-Za-z0-9]/-/g')
  m="$HOME/.claude/projects/$slug/memory/MEMORY.md"
  [ -f "$m" ] || continue
  case "$seen" in *"|$m|"*) continue ;; esac
  seen="$seen|$m|"
  found=1
  echo "### $(short "$m")"
  show "$m" 30
done
[ "$found" -eq 0 ] && echo "  (no project memory)"

section "Plans / TODOs / notes"
found=0
for f in .planning/STATE.md TODO.md TODO NOTES.md PLAN.md ROADMAP.md docs/TODO.md; do
  [ -f "$root/$f" ] || continue
  found=1
  echo "### $f"
  show "$root/$f" 30
done
[ "$found" -eq 0 ] && echo "  (none)"

section "Project type"
found=0
if [ -f "$root/package.json" ]; then
  found=1
  echo "package.json:"
  grep -E '"(name|version)"[[:space:]]*:' "$root/package.json" | head -2 | sed 's/^/  /'
  sed -n '/"scripts"[[:space:]]*:/,/}/p' "$root/package.json" | head -15 | sed 's/^/  /'
fi
for f in pyproject.toml requirements.txt Cargo.toml go.mod Gemfile composer.json pubspec.yaml Package.swift Podfile README.md; do
  if [ -f "$root/$f" ]; then found=1; echo "found: $f"; fi
done
for f in "$root"/*.xcodeproj "$root"/*.xcworkspace; do
  if [ -e "$f" ]; then found=1; echo "found: $(basename "$f")"; fi
done
[ "$found" -eq 0 ] && echo "  (no manifest found)"

# Printed last on purpose: it is the final thing read before acting.
cat <<'RULES'

## Before you act (brain-master hard rules)
1. Broad request with no target (clean up / improve / 정리 / 개선)? Change nothing; offer 2-3 concrete options.
2. Delete, move, rename, merge, commit, push, deploy, install? Only if the request explicitly says so.
3. "Next" / "continue"? Exactly one item, then stop.
4. Never invent facts only the user knows (names, prices, addresses, hours, contacts).
5. Calling something unused? grep the whole project for references first.
6. Copying existing code? Check it against the standing rules above first.
Next: write the one-line "Understood: ... — based on ..." before changing anything.
RULES

exit 0
