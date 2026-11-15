// 用網頁驗證器跑每題 code 的參考解答，確保標準答案能通過
import { readFileSync, readdirSync, statSync } from 'node:fs'; import { join } from 'node:path'; import * as yaml from 'js-yaml';
import { runChecks } from '../src/lib/checker.ts';
const walk = (d) => readdirSync(d).flatMap(f => { const p = join(d, f); return statSync(p).isDirectory() ? walk(p) : p.endsWith('.yaml') ? [p] : []; });
let bad = 0, total = 0;
for (const f of walk('src/content/exercises')) {
  let d; try { d = yaml.load(readFileSync(f, 'utf8')); } catch { continue; }
  if (d?.type !== 'code' || !d.solution) continue; total++;
  const r = runChecks(d.solution, d.checks || []);
  if (!r.ok) { bad++; console.log(f + '\n   ' + r.failures.join('\n   ')); }
}
console.log(`code 題 ${total} 題，參考解未通過 ${bad} 題`);
