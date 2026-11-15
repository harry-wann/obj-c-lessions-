// 以 content.config.ts 的 exerciseBase 規則檢查題目型別
import { readFileSync, readdirSync, statSync } from 'node:fs'; import { join } from 'node:path'; import * as yaml from 'js-yaml';
const walk = (d) => readdirSync(d).flatMap(f => { const p = join(d, f); return statSync(p).isDirectory() ? walk(p) : p.endsWith('.yaml') ? [p] : []; });
let bad = 0;
for (const f of walk('src/content/exercises')) {
  let d; try { d = yaml.load(readFileSync(f, 'utf8')); } catch (e) { bad++; console.log(f + ': YAML 錯誤 ' + e.message.split('\n')[0]); continue; } const issues = [];
  for (const k of ['id','chapter','type','title']) if (typeof d[k] !== 'string') issues.push(`${k} 不是字串`);
  for (const k of ['prompt','solution_note']) if (d[k] != null && typeof d[k] !== 'string') issues.push(`${k} 不是字串`);
  if (d.hints != null && !(Array.isArray(d.hints) && d.hints.every(x => typeof x === 'string'))) issues.push('hints 不是字串陣列');
  if (d.mobile != null && typeof d.mobile !== 'boolean') issues.push('mobile 不是布林');
  if (d.minutes != null && typeof d.minutes !== 'number') issues.push('minutes 不是數字');
  if (d.tier != null && !['basic','advanced','interview'].includes(d.tier)) issues.push('tier 值錯');
  if (d.options && !d.options.every(x => typeof x === 'string')) issues.push('options 含非字串');
  if (d.lines && !d.lines.every(x => typeof x === 'string')) issues.push('lines 含非字串：' + JSON.stringify(d.lines.filter(x => typeof x !== 'string')));
  if (d.reasons && !d.reasons.every(x => typeof x === 'string')) issues.push('reasons 含非字串');
  if (d.accept && !d.accept.every(x => typeof x === 'string')) issues.push('accept 含非字串');
  if (d.steps && !d.steps.every(x => typeof x === 'string')) issues.push('steps 含非字串');
  if (issues.length) { bad++; console.log(f + ': ' + issues.join('；')); }
}
console.log(bad ? `${bad} 檔有問題` : '題目型別全部正確');
