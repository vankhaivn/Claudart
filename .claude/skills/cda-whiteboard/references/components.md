# Building Blocks

Tested pieces for `cda-whiteboard`. They use the host's CSS variables (`--text-primary`, `--text-secondary`, `--text-muted`, `--surface-1`, `--border`, `--border-strong`, `--text-accent`, `--bg-accent`, `--radius`); `scripts/render.sh` defines the same variables for its pages and previews, so a snippet also works inside a rendered Markdown page. Change data, labels and sizes freely; edit the data arrays rather than the markup. Element ids must be unique on a page: rename them when one piece appears twice.

## Mermaid Inline

Mermaid lays out graphs for you; use it when hand-placed boxes would collide. Load it only from a CDN the host allows.

```html
<div id="m" style="padding:0.5rem 0"></div>
<script type="module">
  import mermaid from "https://esm.sh/mermaid@11.4.1/dist/mermaid.esm.min.mjs";
  const mode = document.documentElement.dataset.mode;
  const dark = mode
    ? mode === "dark"
    : matchMedia("(prefers-color-scheme: dark)").matches;
  await document.fonts.ready;
  mermaid.initialize({
    startOnLoad: false,
    theme: "base",
    fontFamily: "inherit",
    themeVariables: {
      darkMode: dark,
      fontSize: "13px",
      lineColor: dark ? "#9c9a92" : "#73726c",
      textColor: dark ? "#c2c0b6" : "#3d3d3a",
      primaryColor: dark ? "#2c2c2a" : "#f1efe8",
      primaryBorderColor: dark ? "#5f5e5a" : "#b4b2a9",
      clusterBkg: "transparent",
      clusterBorder: dark ? "#5f5e5a" : "#d3d1c7",
      edgeLabelBackground: dark ? "#1f1e1d" : "#faf9f5",
    },
  });
  const src = `flowchart LR
  A["Request"] -->|validated| B["Service"] --> C["Store"]`;
  document.getElementById("m").innerHTML = (
    await mermaid.render("m-svg", src)
  ).svg;
</script>
```

Pitfalls seen in practice:

- A label that starts with `1.` or `- ` renders as a Markdown list error. Write `Step 1 · Collect`.
- A subgraph's `direction` is ignored when a node inside it links outside. Link the subgraphs to each other instead.
- An arrow from the last stage back to the first lets Mermaid reorder the stages. End with a node that says where the loop returns.
- A long chain in one row shrinks the text. Wrap it into stacked stages (`flowchart TB` of `direction LR` subgraphs).
- Long text in a rounded `([ ])` node is clipped. Break it with `<br/>`.
- A long subgraph title wraps onto the first node inside it. Keep titles to a few words.
- Nodes with no arrows between them stack vertically whatever the `direction`. For a list of items inside one part, use one node with `<br/>` lines, or hand-built HTML.
- Quote labels with punctuation: `A["Build (CI)"]`.

## Bars With a Reference Mark

For a few numbers in one unit. Values are drawn to scale; `ref` is optional.

```html
<div id="bars" style="padding:0.5rem 0;font-size:14px"></div>
<script>
  {
    const rows = [
      ["Option A", 1.8, "1,8"],
      ["Option B", 1.1, "1,1"],
      ["Option C", 0.76, "0,76", true],
    ];
    const ref = { value: 1, label: "dashed line = 1,0, equal" };
    const max = Math.max(...rows.map((r) => r[1]), ref ? ref.value : 0) * 1.1,
      pct = (v) => (100 * v) / max + "%";
    const box = document.getElementById("bars");
    box.innerHTML =
      '<div style="display:grid;grid-template-columns:minmax(120px,30%) 1fr;gap:10px 16px;align-items:center"></div>';
    for (const [label, v, shown, strong] of rows) {
      const l = document.createElement("div");
      l.style.textAlign = "right";
      l.textContent = label;
      if (strong) l.style.fontWeight = 500;
      const t = document.createElement("div");
      t.style.cssText = "position:relative;height:28px";
      t.innerHTML =
        `<div style="width:${pct(v)};height:100%;border-radius:4px;background:${strong ? "var(--text-accent)" : "var(--border-strong)"}"></div>` +
        `<span style="position:absolute;left:${pct(v)};top:50%;transform:translate(8px,-50%);font-weight:500">${shown}</span>` +
        (ref
          ? `<div style="position:absolute;left:${pct(ref.value)};top:-6px;bottom:-6px;border-left:1.5px dashed var(--text-secondary)"></div>`
          : "");
      box.firstChild.append(l, t);
    }
    if (ref)
      box.insertAdjacentHTML(
        "beforeend",
        `<div style="text-align:right;color:var(--text-muted);font-size:12px;margin-top:6px">${ref.label}</div>`,
      );
  }
</script>
```

In a rendered Markdown page, a fenced `bars` block does the same: one `label | value` per line, plus optional `ref | <value and meaning>` and `unit | <unit>`. Values may use a decimal comma.

## Steps That Open Detail

For a process or pipeline whose steps each carry more than a label. The row stays short; the reader opens the step they care about. Mark steps of one kind (here, the user's decisions) with `kind: 1`.

```html
<style>
  .st {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    align-items: center;
    padding: 0.5rem 0;
  }
  .sb {
    border: 0.5px solid var(--border-strong);
    background: var(--surface-1);
    border-radius: var(--radius);
    padding: 8px 12px;
    font: inherit;
    font-size: 13px;
    color: var(--text-primary);
    cursor: pointer;
  }
  .sb.k1 {
    border-color: var(--text-accent);
    color: var(--text-accent);
  }
  .sb.on {
    outline: 2px solid var(--text-accent);
    outline-offset: 1px;
  }
  .ar {
    color: var(--text-muted);
    font-size: 13px;
  }
  .dp {
    margin-top: 12px;
    border: 0.5px solid var(--border);
    border-radius: 12px;
    padding: 14px 16px;
    font-size: 14px;
    line-height: 1.6;
  }
  .dp ul {
    margin: 6px 0 0;
    padding-left: 20px;
  }
</style>
<div class="st" id="st"></div>
<div class="dp" id="dp"></div>
<script>
  {
    const steps = [
      {
        name: "Collect",
        kind: 0,
        sub: "What this step does",
        points: ["Detail one", "Detail two"],
      },
      {
        name: "Approve",
        kind: 1,
        sub: "The user decides",
        points: ["What they look at"],
      },
    ];
    const tail = "↻ back to Collect";
    const st = document.getElementById("st"),
      dp = document.getElementById("dp");
    steps.forEach((s, i) => {
      if (i) st.insertAdjacentHTML("beforeend", '<span class="ar">→</span>');
      const b = document.createElement("button");
      b.className = "sb" + (s.kind ? " k" + s.kind : "");
      b.textContent = s.name;
      b.onclick = () => show(i);
      st.append(b);
    });
    if (tail)
      st.insertAdjacentHTML("beforeend", `<span class="ar">${tail}</span>`);
    function show(i) {
      st.querySelectorAll(".sb").forEach((b, j) =>
        b.classList.toggle("on", j === i),
      );
      dp.replaceChildren();
      const h = document.createElement("div");
      h.style.fontWeight = 500;
      h.textContent = steps[i].name;
      const s = document.createElement("div");
      s.style.color = "var(--text-secondary)";
      s.textContent = steps[i].sub;
      const ul = document.createElement("ul");
      steps[i].points.forEach((p) => {
        const li = document.createElement("li");
        li.textContent = p;
        ul.append(li);
      });
      dp.append(h, s, ul);
    }
    show(0);
  }
</script>
```

## Week Calendar

For a day-by-day schedule. Rows are weeks starting Monday; `kind` picks the colour. Day and weekday names follow the conversation's language.

```html
<style>
  .cal {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    gap: 4px;
    font-size: 12px;
    padding: 0.5rem 0;
  }
  .cal .hd {
    color: var(--text-secondary);
    text-align: center;
  }
  .cal .c {
    border-radius: 6px;
    padding: 6px 8px;
    min-height: 44px;
    border: 0.5px solid var(--border);
  }
  .cal .c b {
    display: block;
    font-weight: 500;
    font-size: 11px;
    color: var(--text-secondary);
  }
  .cal .k1 {
    background: var(--bg-accent);
    border-color: var(--text-accent);
    color: var(--text-accent);
  }
  .cal .k0 {
    background: var(--surface-1);
  }
  .cal .e {
    border: none;
  }
</style>
<div class="cal" id="cal"></div>
<script>
  {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    const items = { "2026-11-18": [1, "New 1"], "2026-11-19": [0, "Old 1"] };
    const from = new Date(2026, 10, 16),
      to = new Date(2026, 10, 22);
    const cal = document.getElementById("cal"),
      key = (d) => d.toLocaleDateString("sv");
    days.forEach((n) =>
      cal.insertAdjacentHTML("beforeend", `<div class="hd">${n}</div>`),
    );
    for (const d = new Date(from); d <= to; d.setDate(d.getDate() + 1)) {
      const v = items[key(d)],
        c = document.createElement("div");
      c.className = "c " + (v ? "k" + v[0] : "e");
      if (v) {
        const b = document.createElement("b");
        b.textContent = d.getDate() + "/" + (d.getMonth() + 1);
        c.append(b, v[1]);
      }
      cal.append(c);
    }
  }
</script>
```

Add a one-line legend under the calendar when the colours are not obvious from the labels.
