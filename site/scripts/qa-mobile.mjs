// 手機尺寸 QA：先 npm run build && npx astro preview --port 4321，再 node scripts/qa-mobile.mjs
// 檢查每頁的橫向溢出、JS 錯誤、課文頁是否有練習題
const { chromium, devices } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright');
import { readdirSync } from 'node:fs';
const b = await chromium.launch(); const ctx = await b.newContext({ ...devices['iPhone 13'] }); const p = await ctx.newPage();
const base = 'http://localhost:4321/obj-c-lessions-';
const errs = []; p.on('pageerror', e => errs.push(p.url() + ' ' + e.message));
const dist = new URL('../dist/lessons', import.meta.url).pathname;
const paths = readdirSync(dist).filter(m => m.startsWith('m')).flatMap(m => readdirSync(`${dist}/${m}`).map(c => `/lessons/${m}/${c}`));
paths.push('/', '/lessons', '/exercises', '/project', '/cheatsheet', '/cheatsheet/syntax', '/cheatsheet/crashes', '/cheatsheet/compare', '/cheatsheet/terms', '/cheatsheet/interview', '/settings');
const issues = []; let totalEx = 0;
for (const path of paths) {
  await p.goto(base + path, { waitUntil: 'networkidle' });
  await p.evaluate(() => window.scrollTo(0, document.body.scrollHeight)); await p.waitForTimeout(250);
  const r = await p.evaluate(() => ({ sw: document.documentElement.scrollWidth, cw: document.documentElement.clientWidth, ex: document.querySelectorAll('section[id^=ex-]').length, unknown: [...document.querySelectorAll('section[id^=ex-]')].filter(s => s.textContent.includes('未知題型')).length }));
  totalEx += r.ex;
  if (r.sw > r.cw + 1 || r.unknown) issues.push({ path, ...r });
  if (path.startsWith('/lessons/m') && r.ex === 0) issues.push({ path, note: 'no exercises' });
}
console.log('pages', paths.length, 'exercise sections', totalEx);
console.log('issues', JSON.stringify(issues, null, 1));
console.log('errors', errs.slice(0, 10));
await b.close();
