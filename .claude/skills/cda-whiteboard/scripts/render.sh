#!/usr/bin/env bash
# Render a visual explanation to a standalone HTML page.
#   render.sh <page.md> [out.html]                Markdown with ```mermaid and ```bars blocks
#   render.sh --preview <fragment.html> [out.html] an inline-visual fragment, shown light and dark at chat width
# Pages load marked and mermaid from jsDelivr, so viewing them needs the network.
set -euo pipefail

usage() { echo "usage: render.sh <page.md> [out.html] | render.sh --preview <fragment.html> [out.html]" >&2; exit 2; }

mode=page
if [ "${1:-}" = "--preview" ]; then mode=preview; shift; fi
in=${1:-}; [ -n "$in" ] || usage
[ -f "$in" ] || { echo "render.sh: no such file: $in" >&2; exit 1; }
if [ "$mode" = preview ]; then out=${2:-${in%.*}.preview.html}; else out=${2:-${in%.*}.html}; fi

# Host-like theme: the variables and SVG classes an inline visual may use.
host_css() {
  cat <<'CSS'
:root, [data-mode="light"] {
  --text-primary:#1f1e1d; --text-secondary:#5f5e5a; --text-muted:#888780;
  --text-accent:#185fa5; --text-success:#3b6d11; --text-warning:#854f0b; --text-danger:#a32d2d;
  --surface-0:#faf9f5; --surface-1:#f1efe8; --surface-2:#ffffff;
  --bg-accent:#e6f1fb; --bg-success:#eaf3de; --bg-warning:#faeeda; --bg-danger:#fcebeb;
  --border:rgba(31,30,29,.14); --border-strong:rgba(31,30,29,.28); --border-stronger:rgba(31,30,29,.45);
  --border-accent:#185fa5; --border-success:#3b6d11; --border-warning:#854f0b; --border-danger:#a32d2d;
  --font-sans:-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; --font-mono:ui-monospace, Menlo, monospace;
  --font-voice:Georgia, serif; --radius:8px;
  --p:var(--text-primary); --s:var(--text-secondary); --t:var(--text-muted); --bg2:var(--surface-1); --b:var(--border);
}
[data-mode="dark"] {
  --text-primary:#e8e6dc; --text-secondary:#b4b2a9; --text-muted:#888780;
  --text-accent:#85b7eb; --text-success:#97c459; --text-warning:#ef9f27; --text-danger:#f09595;
  --surface-0:#1f1e1d; --surface-1:#2c2c2a; --surface-2:#262624;
  --bg-accent:#0c447c; --bg-success:#27500a; --bg-warning:#633806; --bg-danger:#791f1f;
  --border:rgba(232,230,220,.14); --border-strong:rgba(232,230,220,.28); --border-stronger:rgba(232,230,220,.45);
  --border-accent:#85b7eb; --border-success:#97c459; --border-warning:#ef9f27; --border-danger:#f09595;
}
@media (prefers-color-scheme: dark) { :root:not([data-mode]) {
  --text-primary:#e8e6dc; --text-secondary:#b4b2a9; --text-muted:#888780;
  --text-accent:#85b7eb; --text-success:#97c459; --text-warning:#ef9f27; --text-danger:#f09595;
  --surface-0:#1f1e1d; --surface-1:#2c2c2a; --surface-2:#262624;
  --bg-accent:#0c447c; --bg-success:#27500a; --bg-warning:#633806; --bg-danger:#791f1f;
  --border:rgba(232,230,220,.14); --border-strong:rgba(232,230,220,.28); --border-stronger:rgba(232,230,220,.45);
  --border-accent:#85b7eb; --border-success:#97c459; --border-warning:#ef9f27; --border-danger:#f09595;
} }
.sr-only { position:absolute; width:1px; height:1px; overflow:hidden; clip:rect(0 0 0 0); white-space:nowrap; }
svg .t, svg .th { font:14px var(--font-sans); fill:var(--text-primary); } svg .th { font-weight:500; }
svg .ts { font:12px var(--font-sans); fill:var(--text-secondary); }
svg .box { fill:var(--surface-1); stroke:var(--border-strong); }
svg .arr { stroke:var(--text-secondary); stroke-width:1.5; fill:none; }
svg .leader { stroke:var(--text-muted); stroke-width:.5; stroke-dasharray:3 3; fill:none; }
svg .node { cursor:pointer; } svg .node:hover { opacity:.85; }
CSS
  # c-{ramp}: light = 50 fill, 600 stroke, 800/600 text; dark = 800 fill, 200 stroke, 100/200 text.
  local r
  for r in "purple EEEDFE 534AB7 3C3489 CECBF6 AFA9EC" "teal E1F5EE 0F6E56 085041 9FE1CB 5DCAA5" \
           "coral FAECE7 993C1D 712B13 F5C4B3 F0997B" "pink FBEAF0 993556 72243E F4C0D1 ED93B1" \
           "gray F1EFE8 5F5E5A 444441 D3D1C7 B4B2A9" "blue E6F1FB 185FA5 0C447C B5D4F4 85B7EB" \
           "green EAF3DE 3B6D11 27500A C0DD97 97C459" "amber FAEEDA 854F0B 633806 FAC775 EF9F27" \
           "red FCEBEB A32D2D 791F1F F7C1C1 F09595"; do
    set -- $r
    printf '.c-%s>rect,.c-%s>circle,.c-%s>ellipse,rect.c-%s,circle.c-%s,ellipse.c-%s{fill:#%s;stroke:#%s}\n' "$1" "$1" "$1" "$1" "$1" "$1" "$2" "$3"
    printf '.c-%s>.t,.c-%s>.th{fill:#%s}.c-%s>.ts{fill:#%s}\n' "$1" "$1" "$4" "$1" "$3"
    printf '[data-mode="dark"] .c-%s>rect,[data-mode="dark"] .c-%s>circle,[data-mode="dark"] .c-%s>ellipse,[data-mode="dark"] rect.c-%s{fill:#%s;stroke:#%s}\n' "$1" "$1" "$1" "$1" "$4" "$6"
    printf '[data-mode="dark"] .c-%s>.t,[data-mode="dark"] .c-%s>.th{fill:#%s}[data-mode="dark"] .c-%s>.ts{fill:#%s}\n' "$1" "$1" "$5" "$1" "$6"
  done
}

esc_title() { printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g'; }

if [ "$mode" = preview ]; then
  # Each theme renders in its own iframe so ids and scripts in the fragment do not collide.
  frame=$(mktemp)
  trap 'rm -f "$frame"' EXIT
  {
    printf '<!doctype html><html data-mode="__MODE__"><head><meta charset="utf-8"><style>\n'
    host_css
    cat <<'CSS'
html,body{margin:0;background:var(--surface-0);color:var(--text-primary);font:16px/1.7 var(--font-sans)}
body{padding:16px 20px}
CSS
    printf '</style></head><body>\n'
    cat "$in"
    cat <<'JS'
<script>new ResizeObserver(()=>parent.postMessage({f:"__MODE__",h:document.documentElement.scrollHeight},"*")).observe(document.documentElement)</script>
</body></html>
JS
  } > "$frame"
  srcdoc() { sed "s/__MODE__/$1/g" "$frame" | sed 's/&/\&amp;/g; s/"/\&quot;/g'; }
  {
    cat <<HTML
<!doctype html><html><head><meta charset="utf-8"><title>Preview: $(esc_title "$(basename "$in")")</title>
<style>
body{margin:0;padding:24px;background:#8a8a85;font:13px -apple-system,BlinkMacSystemFont,sans-serif;color:#fff}
.row{display:flex;flex-wrap:wrap;gap:24px;align-items:flex-start}
figure{margin:0} figcaption{margin-bottom:6px}
iframe{border:0;border-radius:12px;width:var(--w);height:200px;background:#fff;display:block}
</style></head><body>
<p>Chat width <select id="w"><option>680</option><option selected>760</option><option>1000</option></select> px</p>
<div class="row">
<figure><figcaption>light</figcaption><iframe id="light" srcdoc="$(srcdoc light)"></iframe></figure>
<figure><figcaption>dark</figcaption><iframe id="dark" srcdoc="$(srcdoc dark)"></iframe></figure>
</div>
<script>
const w=document.getElementById('w'),set=()=>document.querySelectorAll('iframe').forEach(f=>f.style.setProperty('--w',w.value+'px'));
w.onchange=set;set();
addEventListener('message',e=>{const f=document.getElementById(e.data&&e.data.f);if(f)f.style.height=e.data.h+'px'});
</script></body></html>
HTML
  } > "$out"
  echo "$out"
  exit 0
fi

title=$(sed -n 's/^# //p' "$in" | head -n 1)
title=$(esc_title "${title:-Explanation}")
{
  cat <<HTML
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title}</title>
<style>
HTML
  host_css
  cat <<'CSS'
* { box-sizing:border-box; }
body { margin:0; background:var(--surface-0); color:var(--text-primary); font:16px/1.6 var(--font-sans); }
main { max-width:1240px; margin:0 auto; padding:40px 24px 64px; }
h1 { font-size:26px; line-height:1.3; margin:0 0 8px; font-weight:600; }
h1 + p { font-size:19px; margin:0 0 32px; max-width:900px; }
h2 { font-size:18px; font-weight:600; margin:40px 0 12px; padding-top:20px; border-top:1px solid var(--border); }
p, li { max-width:900px; }
ul { padding-left:22px; } li { margin:4px 0; }
code { background:var(--surface-1); padding:1px 5px; border-radius:4px; font:14px var(--font-mono); }
.mermaid, .bars { background:var(--surface-2); border:1px solid var(--border); border-radius:10px; padding:20px; margin:12px 0 16px; overflow-x:auto; }
.mermaid { text-align:center; } .mermaid svg { height:auto; }
.scroll { overflow-x:auto; }
table { border-collapse:collapse; width:100%; margin:12px 0 16px; background:var(--surface-2); font-size:15px; }
th, td { border:1px solid var(--border); padding:8px 12px; text-align:left; vertical-align:top; }
th { background:var(--surface-1); font-weight:600; }
a { color:var(--text-accent); }
.bar-row { display:grid; grid-template-columns:minmax(140px, 30%) 1fr; gap:16px; align-items:center; margin:10px 0; }
.bar-label { text-align:right; font-size:15px; }
.bar-track { position:relative; height:30px; }
.bar-fill { height:100%; background:var(--text-accent); border-radius:4px; }
.bar-value { position:absolute; top:50%; transform:translate(8px, -50%); font-weight:600; font-size:15px; white-space:nowrap; }
.bar-ref { position:absolute; top:-6px; bottom:-6px; border-left:2px dashed var(--text-primary); }
.bar-note { color:var(--text-secondary); font-size:13px; text-align:right; margin-top:8px; }
.bar-swatch { display:inline-block; height:14px; border-left:2px dashed var(--text-primary); margin-right:8px; vertical-align:-2px; }
.err { color:var(--text-danger); white-space:pre-wrap; text-align:left; font:13px var(--font-mono); }
@media (max-width:640px) { main { padding:24px 16px 48px; } h1 { font-size:22px; } }
CSS
  cat <<'HTML'
</style>
</head>
<body>
<main id="page"></main>
<script type="text/markdown" id="src">
HTML
  # Keep the Markdown source inert inside the script tag.
  sed 's#</script#<\\/script#g' "$in"
  cat <<'HTML'
</script>
<script src="https://cdn.jsdelivr.net/npm/marked@12.0.2/marked.min.js"></script>
<script type="module">
  import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.esm.min.mjs";
  const page = document.getElementById("page");
  const src = document.getElementById("src").textContent.replace(/<\\\/script/g, "</script");
  page.innerHTML = marked.parse(src);
  // Raw HTML blocks inserted by innerHTML do not run their scripts; re-create them so components work.
  page.querySelectorAll("script").forEach(old => { const s = document.createElement("script"); [...old.attributes].forEach(a => s.setAttribute(a.name, a.value)); s.textContent = old.textContent; old.replaceWith(s); });
  page.querySelectorAll("table").forEach(t => { const w = document.createElement("div"); w.className = "scroll"; t.replaceWith(w); w.appendChild(t); });
  page.querySelectorAll("pre > code.language-mermaid").forEach(c => {
    const d = document.createElement("div"); d.className = "mermaid"; d.textContent = c.textContent; c.parentElement.replaceWith(d);
  });
  // ```bars: one "label | value" per line; "ref | value and meaning" draws a reference mark, "unit | text" names the unit.
  page.querySelectorAll("pre > code.language-bars").forEach(c => {
    const rows = [], opt = {};
    for (const line of c.textContent.split("\n")) {
      const [k, v] = line.split("|").map(x => x && x.trim());
      if (!k || v === undefined) continue;
      if (k === "ref" || k === "unit") opt[k] = v; else rows.push([k, v]);
    }
    const num = v => parseFloat(String(v).replace(",", "."));
    const ref = opt.ref !== undefined ? num(opt.ref) : null;
    const max = Math.max(...rows.map(r => num(r[1])), ref ?? 0) * 1.08;
    const pct = v => (100 * v / max).toFixed(2) + "%";
    const box = document.createElement("div"); box.className = "bars";
    for (const [label, value] of rows) {
      const row = document.createElement("div"); row.className = "bar-row";
      row.innerHTML = '<div class="bar-label"></div><div class="bar-track"><div class="bar-fill"></div><span class="bar-value"></span></div>';
      row.querySelector(".bar-label").textContent = label;
      row.querySelector(".bar-fill").style.width = pct(num(value));
      const val = row.querySelector(".bar-value"); val.textContent = value + (opt.unit ? " " + opt.unit : ""); val.style.left = pct(num(value));
      if (ref !== null) { const m = document.createElement("div"); m.className = "bar-ref"; m.style.left = pct(ref); row.querySelector(".bar-track").appendChild(m); }
      box.appendChild(row);
    }
    if (ref !== null) { const n = document.createElement("div"); n.className = "bar-note"; n.innerHTML = '<span class="bar-swatch"></span>'; n.append(opt.ref); box.appendChild(n); }
    c.parentElement.replaceWith(box);
  });
  const dark = matchMedia("(prefers-color-scheme: dark)").matches;
  mermaid.initialize({ startOnLoad:false, theme: dark ? "dark" : "neutral", securityLevel:"strict",
    fontFamily:"-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
    flowchart:{ htmlLabels:true, curve:"basis", padding:12, useMaxWidth:false }, gantt:{ barHeight:22, fontSize:13 },
    sequence:{ useMaxWidth:false }, state:{ useMaxWidth:false } });
  for (const d of page.querySelectorAll(".mermaid")) {
    try { await mermaid.run({ nodes:[d] }); }
    catch (e) { d.innerHTML = '<div class="err">Mermaid error: ' + String(e.message || e).replace(/</g, "&lt;") + "</div>"; }
  }
</script>
</body>
</html>
HTML
} > "$out"

echo "$out"
