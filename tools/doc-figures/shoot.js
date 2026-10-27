// Screenshot the pages built by figures.R into man/figures and vignettes/figures.
// Usage (from the package root): node tools/doc-figures/shoot.js <out_dir>
const { chromium } = require("playwright");
const { spawn, execFileSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const outDir = path.resolve(process.argv[2]);
const manifest = JSON.parse(fs.readFileSync(path.join(outDir, "manifest.json"), "utf8"));
const dest = { readme: "man/figures", vignette: "vignettes/figures" };
const prefix = { readme: "README-", vignette: "" };

async function waitForServer(url, ms = 30000) {
  const t0 = Date.now();
  while (Date.now() - t0 < ms) {
    try { const r = await fetch(url); if (r.ok) return; } catch (e) {}
    await new Promise(r => setTimeout(r, 300));
  }
  throw new Error("Shiny app did not start: " + url);
}

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1200, height: 900 }, deviceScaleFactor: 2 });
  let port = 7311;

  for (const fig of manifest) {
    let server = null;

    if (fig.app) {
      port += 1;
      server = spawn("Rscript", [path.join(outDir, fig.app)], { env: { ...process.env, PORT: String(port) }, stdio: "ignore" });
      await waitForServer(`http://127.0.0.1:${port}`);
      await page.goto(`http://127.0.0.1:${port}`);
      await page.waitForSelector("table.pvtUi");
    } else {
      await page.goto("file://" + path.join(outDir, fig.name + ".html"));
      await page.waitForSelector("table.pvtUi");
    }
    await page.waitForTimeout(900);

    if (fig.open_filter) {
      await page.locator(`.pvtAxisContainer li span.pvtAttr`, { hasText: fig.open_filter })
        .locator(".pvtTriangle").click();
      await page.waitForTimeout(300);
    }

    // Area to capture: the pivot UI (plus an open filter box), just the
    // unused-variable pills, or the whole Shiny page.
    const box = await page.evaluate(([crop]) => {
      const pad = crop === "unused" ? 2 : 12;
      const rect = (el) => el.getBoundingClientRect();
      let els;
      if (crop === "unused") els = [document.querySelector("td.pvtUnused")];
      else if (crop === "page") els = Array.from(document.querySelectorAll("h2, .well, .bslib-sidebar-layout > .sidebar, table.pvtUi, .shiny-download-link"));
      else els = [document.querySelector("table.pvtUi"), document.querySelector(".pvtFilterBox:not([style*='none'])")];
      const rs = els.filter(Boolean).map(rect).filter(r => r.width > 0);
      if (crop === "page") {
        // Full app width, but stop just below the pivot table (sidebar
        // layouts stretch to the window height).
        const layout = document.querySelector(".bslib-sidebar-layout, .container-fluid > .row") || document.body;
        const L = rect(layout), title = document.querySelector("h2");
        const bottom = Math.max(...rs.map(r => r.bottom));
        const top = title ? rect(title).top : L.top;
        return { x: Math.max(0, L.left - pad), y: Math.max(0, top - pad), width: L.width + 2 * pad, height: bottom - top + 2 * pad };
      }
      const x0 = Math.min(...rs.map(r => r.left)), y0 = Math.min(...rs.map(r => r.top));
      const x1 = Math.max(...rs.map(r => r.right)), y1 = Math.max(...rs.map(r => r.bottom));
      return { x: Math.max(0, x0 - pad), y: Math.max(0, y0 - pad), width: x1 - x0 + 2 * pad, height: y1 - y0 + 2 * pad };
    }, [fig.crop]);

    const tmp = path.join(outDir, fig.name + ".png");
    await page.screenshot({ path: tmp, clip: box });

    for (const t of fig.targets) {
      fs.mkdirSync(dest[t], { recursive: true });
      fs.copyFileSync(tmp, path.join(dest[t], prefix[t] + fig.name + ".png"));
    }
    console.log("shot", fig.name, Math.round(box.width) + "x" + Math.round(box.height));

    if (server) server.kill();
  }

  await browser.close();
})();
