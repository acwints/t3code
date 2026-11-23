// Renders aw-violet.svg to the PNG the macOS build turns into icon.icns.
// Run: node fork/icon/render.mjs
import * as NodeFS from "node:fs";
import * as NodeModule from "node:module";
import * as NodeURL from "node:url";

// playwright is a dependency of apps/web, not of this folder.
const { chromium } = NodeModule.createRequire(
  new URL("../../apps/web/package.json", import.meta.url),
)("playwright");

const here = (file) => NodeURL.fileURLToPath(new URL(file, import.meta.url));
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1024, height: 1024 } });
await page.setContent(
  `<body style="margin:0">${NodeFS.readFileSync(here("aw-violet.svg"), "utf8")}</body>`,
);
await page
  .locator("svg")
  .screenshot({ path: here("../../assets/prod/black-macos-1024.png"), omitBackground: true });
await browser.close();
