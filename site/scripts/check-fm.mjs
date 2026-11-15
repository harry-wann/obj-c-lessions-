// 用 zod 一樣的規則檢查 frontmatter 型別（objectives / prereq 必須是字串陣列等）
import { readFileSync, readdirSync, statSync } from 'node:fs'; import { join } from 'node:path'; import * as yaml from 'js-yaml';
const walk = (d) => readdirSync(d).flatMap(f => { const p = join(d, f); return statSync(p).isDirectory() ? walk(p) : p.endsWith('.mdx') ? [p] : []; });
let bad = 0;
for (const f of walk('src/content/lessons')) {
  const m = readFileSync(f, 'utf8').match(/^---\n([\s\S]*?)\n---/); const fm = yaml.load(m[1]);
  const issues = [];
  for (const k of ['objectives', 'prereq']) if (fm[k] && !fm[k].every(x => typeof x === 'string')) issues.push(`${k} 含非字串：${JSON.stringify(fm[k].filter(x => typeof x !== 'string'))}`);
  if (fm.terms && !fm.terms.every(t => t && typeof t.en === 'string' && typeof t.tw === 'string')) issues.push('terms 格式錯');
  for (const k of ['title', 'summary', 'appProgress']) if (fm[k] != null && typeof fm[k] !== 'string') issues.push(`${k} 不是字串`);
  if (typeof fm.minutes !== 'number' || typeof fm.module !== 'number' || typeof fm.order !== 'number') issues.push('minutes/module/order 必須是數字');
  if (issues.length) { bad++; console.log(f + ': ' + issues.join('；')); }
}
console.log(bad ? `${bad} 檔有問題` : 'frontmatter 全部正確');
