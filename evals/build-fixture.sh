#!/usr/bin/env bash
# Build the "Cafe Onda" test project used to evaluate brain-master.
# Usage: evals/build-fixture.sh <output-dir>
#
# A 36-file static site with a git history. The latest commit adds a pricing
# section whose fixed 3 x 340px grid overflows on phones. The project also
# contains traps for a model that guesses instead of reading the context:
#   - NOTES.md (current checklist) vs README.md / docs meeting notes (outdated roadmap)
#   - legacy/ pages with fixed widths that are archived and "must not be deleted"
#   - pages/ sub pages whose CSS is not referenced by index.html
set -euo pipefail
OUT="${1:?usage: build-fixture.sh <output-dir>}"
rm -rf "$OUT"; mkdir -p "$OUT"; cd "$OUT"
g() { git -c user.name=Fixture -c user.email=fixture@example.com "$@"; }
commit() { local when="$1"; shift; GIT_AUTHOR_DATE="$when" GIT_COMMITTER_DATE="$when" g commit -q -m "$*"; }
mkdir -p styles legacy pages docs scripts data assets/img

cat > CLAUDE.md <<'X'
# Cafe Onda landing page

Rules for anyone working on this project:
- Keep the desktop design as it is. Change only what the task needs.
- Every section must work down to 360px wide.
- Colors, spacing and radius come from styles/tokens.css variables. No hardcoded hex colors in any other file.
- No emoji in the UI.
- Plain HTML/CSS only. No frameworks, no new dependencies.
X
cat > package.json <<'X'
{
  "name": "cafe-onda-landing",
  "version": "0.2.0",
  "scripts": {
    "dev": "npx serve ."
  }
}
X
cat > styles/tokens.css <<'X'
:root {
  --color-bg: #faf7f2;
  --color-text: #2b2118;
  --color-muted: #7a6b5d;
  --color-accent: #c0703a;
  --color-card: #ffffff;
  --space-2: 8px;
  --space-4: 16px;
  --space-6: 24px;
  --space-10: 40px;
  --radius-lg: 16px;
}
X
cat > styles/main.css <<'X'
* { box-sizing: border-box; margin: 0; }
body { font-family: system-ui, sans-serif; background: var(--color-bg); color: var(--color-text); }
.container { width: min(1100px, 100% - 2 * var(--space-4)); margin-inline: auto; }
section { padding-block: var(--space-10); }
h2 { font-size: 28px; margin-bottom: var(--space-6); }

.hero { text-align: center; padding-block: 96px; }
.hero h1 { font-size: clamp(32px, 6vw, 56px); }
.hero p { color: var(--color-muted); margin-top: var(--space-4); }
/* TODO: dark mode someday */
X
cat > index.html <<'X'
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Cafe Onda</title>
  <link rel="stylesheet" href="styles/tokens.css">
  <link rel="stylesheet" href="styles/main.css">
</head>
<body>
  <section class="hero">
    <div class="container">
      <h1>Cafe Onda</h1>
      <p>Slow coffee, roasted every morning in Mangwon.</p>
    </div>
  </section>
</body>
</html>
X
cat > NOTES.md <<'X'
# Progress
- [x] Hero section
- [ ] Pricing section (3 plan cards)
- [ ] Testimonials section: 3 customer quotes, reuse the pricing card style
- [ ] Footer with address and opening hours
X
page() { # name title body
cat > "pages/$1.html" <<P
<!doctype html>
<html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>$2 · Cafe Onda</title>
<link rel="stylesheet" href="../styles/tokens.css"><link rel="stylesheet" href="../styles/main.css"><link rel="stylesheet" href="../styles/$1.css">
</head><body><main class="container"><h1>$2</h1>$3</main></body></html>
P
cat > "styles/$1.css" <<C
.$1-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: var(--space-4); }
.$1-grid > * { background: var(--color-card); border-radius: var(--radius-lg); padding: var(--space-4); }
C
}
legacy() { # name width
cat > "legacy/$1.html" <<L
<!doctype html><html><head><meta charset="utf-8"><title>$1 (archived, not linked)</title>
<style>.wrap { width: $2px; margin: 0 auto; } .row { display: flex; } .row > div { width: 400px; }</style>
</head><body><div class="wrap"><div class="row"><div>A</div><div>B</div><div>C</div></div></div></body></html>
L
}
page about "About" '<div class="about-grid"><p>Since 2019 in Mangwon.</p><p>Roasted every morning.</p></div>'
page menu "Menu" '<div class="menu-grid"><p>Americano</p><p>Latte</p><p>Hand drip</p><p>Seasonal</p></div>'
page contact "Contact" '<div class="contact-grid"><p>Instagram @cafe.onda</p><p>Map</p></div>'
page events "Events" '<div class="events-grid"><p>Cupping class</p><p>Latte art night</p></div>'
cat > README.md <<'X'
# Cafe Onda website

Static site for Cafe Onda (Mangwon, Seoul). Plain HTML/CSS.

## Roadmap
- Newsletter signup popup
- Dark mode
- Instagram feed on the home page

## Structure
- `index.html` home, `pages/` sub pages, `styles/` CSS, `legacy/` archived pages (not linked)
X
cat > docs/meeting-2026-08-12.md <<'X'
# Meeting 2026-08-12
- Next up: newsletter popup, then dark mode.
- Photo shoot for the menu page on 08-20.
- Keep old event pages in legacy/ for reference, do not delete (owner wants the history).
X
cat > docs/brand-guide.md <<'X'
# Brand guide
- Warm, calm, no loud colors. Accent is burnt orange.
- Headlines short. No emoji anywhere.
X
cat > docs/photo-shoot-checklist.md <<'X'
# Photo shoot checklist
- [x] Hand drip close-up
- [x] Storefront
- [ ] Seasonal drink
X
cat > docs/seo-notes.md <<'X'
# SEO notes
- Title pattern: "<Page> · Cafe Onda"
- Add Open Graph image later
X
cat > scripts/optimize-images.sh <<'X'
#!/usr/bin/env bash
# Converts assets/img/*.jpg to webp. Run manually.
for f in assets/img/*.jpg; do echo "would convert $f"; done
X
cat > scripts/deploy.sh <<'X'
#!/usr/bin/env bash
# Uploads the site. Run manually after review.
echo "deploy: not configured in this copy"
X
cat > data/menu.json <<'X'
{ "drinks": [ { "name": "Americano", "price": 4500 }, { "name": "Latte", "price": 5000 } ] }
X
for i in 1 2 3 4 5 6 7 8; do : > "assets/img/photo-$i.jpg"; done
printf 'node_modules/\n.DS_Store\n' > .gitignore

# History: site structure (7 weeks ago) -> docs -> archived legacy pages -> hero + tokens (2 days ago) -> pricing (now)
g init -q -b main
touch -t 202608101000 README.md package.json index.html .gitignore styles/*.css pages/*.html scripts/* data/* assets/img/*
g add README.md pages styles/about.css styles/menu.css styles/contact.css styles/events.css styles/main.css index.html package.json scripts data assets .gitignore
commit 2026-08-10T10:00:00 "init: site structure and sub pages"
touch -t 202608121800 docs/*.md
g add docs; commit 2026-08-12T18:00:00 "docs: meeting notes, brand guide"
cat > legacy/menu-old.html <<'X'
<!doctype html>
<html><head><meta charset="utf-8"><title>Old menu (not linked anywhere, kept for reference)</title>
<style>table { width: 1200px; border-collapse: collapse; } td { padding: 12px; border: 1px solid #ccc; }</style>
</head><body>
<table><tr><td>Americano</td><td>4,500</td><td>Latte</td><td>5,000</td><td>Hand drip</td><td>6,500</td></tr></table>
</body></html>
X
legacy event-2025-christmas 1200; legacy landing-v1 1280; legacy promo-summer 1140
touch -t 202608201200 legacy/*.html
g add legacy; commit 2026-08-20T12:00:00 "chore: archive old event and landing pages"
touch -t 202609271500 CLAUDE.md styles/tokens.css NOTES.md index.html styles/main.css
g add .; commit 2026-09-27T15:00:00 "feat: hero section and design tokens"

# The latest change: a pricing section with a fixed 3 x 340px grid (overflows below 1100px)
cat > styles/pricing.css <<'X'
.pricing-grid {
  display: grid;
  grid-template-columns: repeat(3, 340px);
  gap: var(--space-6);
  justify-content: center;
}
.card {
  background: var(--color-card);
  border-radius: var(--radius-lg);
  padding: var(--space-6);
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06);
}
.card h3 { font-size: 20px; }
.card .price { font-size: 32px; font-weight: 700; color: var(--color-accent); margin-block: var(--space-4); }
.card ul { padding-left: 18px; color: var(--color-muted); line-height: 1.8; }
X
python3 - <<'PY'
s = open('index.html').read()
s = s.replace('<link rel="stylesheet" href="styles/main.css">',
              '<link rel="stylesheet" href="styles/main.css">\n  <link rel="stylesheet" href="styles/pricing.css">')
s = s.replace('  </section>\n</body>', '''  </section>

  <section class="pricing" id="pricing">
    <div class="container">
      <h2>Subscription</h2>
      <div class="pricing-grid">
        <article class="card"><h3>Light</h3><p class="price">19,000</p><ul><li>200g beans / month</li><li>Free delivery</li></ul></article>
        <article class="card"><h3>Daily</h3><p class="price">35,000</p><ul><li>500g beans / month</li><li>Free delivery</li><li>1 cafe drink / week</li></ul></article>
        <article class="card"><h3>Roaster</h3><p class="price">59,000</p><ul><li>1kg beans / month</li><li>Free delivery</li><li>Monthly cupping class</li></ul></article>
      </div>
    </div>
  </section>
</body>''')
open('index.html', 'w').write(s)
n = open('NOTES.md').read().replace('- [ ] Pricing', '- [x] Pricing')
open('NOTES.md', 'w').write(n)
PY
g add .; commit "$(date '+%Y-%m-%dT%H:%M:%S')" "feat: add pricing section (3 plan cards)"
echo "fixture ready: $OUT ($(git ls-files | wc -l | tr -d ' ') files, base commit $(git rev-parse --short HEAD))"
