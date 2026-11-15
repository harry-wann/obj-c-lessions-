// 檢查題目 YAML 與課文 MDX frontmatter（不需 astro）
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, relative, basename } from 'node:path';
import * as yaml from 'js-yaml';
const root = new URL('../src/content/', import.meta.url).pathname;
const walk = (d, ext) => readdirSync(d).flatMap(f => { const p = join(d, f); return statSync(p).isDirectory() ? walk(p, ext) : p.endsWith(ext) ? [p] : []; });
const errors = []; const ids = new Set(); const chapters = new Set();
const TYPES = ['quiz','fill','parsons','predict','spot','crash','code','xcode','flash'];
const REQ = { quiz: ['options','answer'], fill: ['code','blanks'], parsons: ['lines'], predict: ['code','accept'], spot: ['code','bug_lines','reasons','answer_reason'], crash: ['log','options','answer'], code: ['checks'], xcode: [], flash: ['front','back'] };
for (const f of walk(join(root, 'lessons'), '.mdx')) {
  const rel = relative(root, f); const src = readFileSync(f, 'utf8'); const m = src.match(/^---\n([\s\S]*?)\n---/);
  if (!m) { errors.push(`${rel}: 缺少 frontmatter`); continue; }
  let fm; try { fm = yaml.load(m[1]); } catch (e) { errors.push(`${rel}: frontmatter YAML 錯誤 ${e.message}`); continue; }
  for (const k of ['title','module','chapter','order']) if (fm[k] == null) errors.push(`${rel}: frontmatter 缺 ${k}`);
  if (typeof fm.chapter !== 'string') errors.push(`${rel}: chapter 必須是字串（加引號）`);
  chapters.add(fm.chapter);
  const body = src.slice(m[0].length);
  for (const c of ['Compare','Pitfall','Crash','Tip','Term','Steps']) if (new RegExp(`<${c}[\\s>]`).test(body) && !new RegExp(`import ${c} from`).test(body)) errors.push(`${rel}: 用了 <${c}> 但沒有 import`);
  const fences = (body.match(/```/g) || []).length; if (fences % 2) errors.push(`${rel}: 程式碼圍欄數量為奇數`);
  if (!/<Crash/.test(body)) errors.push(`${rel}: 警告：沒有 <Crash>（崩潰現場）`);
  if (!/<Pitfall/.test(body)) errors.push(`${rel}: 警告：沒有 <Pitfall>`);
}
for (const f of walk(join(root, 'exercises'), '.yaml')) {
  const rel = relative(root, f); let d; try { d = yaml.load(readFileSync(f, 'utf8')); } catch (e) { errors.push(`${rel}: YAML 錯誤 ${e.message}`); continue; }
  for (const k of ['id','chapter','type','title']) if (d[k] == null) errors.push(`${rel}: 缺 ${k}`);
  if (d.id && d.id !== basename(f, '.yaml').replace(/^/, rel.split('/')[1] + '-')) errors.push(`${rel}: id「${d.id}」應等於「${rel.split('/')[1]}-${basename(f, '.yaml')}」`);
  if (ids.has(d.id)) errors.push(`${rel}: id 重複 ${d.id}`); ids.add(d.id);
  if (!TYPES.includes(d.type)) errors.push(`${rel}: 未知 type ${d.type}`);
  else for (const k of REQ[d.type]) if (d[k] == null) errors.push(`${rel}: ${d.type} 題缺 ${k}`);
  if (typeof d.chapter !== 'string') errors.push(`${rel}: chapter 必須是字串（加引號）`);
  if (d.type === 'quiz' && typeof d.answer === 'number' && d.answer >= d.options.length) errors.push(`${rel}: answer 超出 options`);
  if (d.type === 'spot' && d.answer_reason >= d.reasons.length) errors.push(`${rel}: answer_reason 超出 reasons`);
  if (d.type === 'crash' && d.answer >= d.options.length) errors.push(`${rel}: answer 超出 options`);
  if (d.type === 'fill') { const n = (d.code.match(/___\d+___/g) || []).length; if (n !== Object.keys(d.blanks).length) errors.push(`${rel}: 空格數 ${n} 與 blanks ${Object.keys(d.blanks).length} 不符`); }
  if (d.type === 'code') for (const c of d.checks) for (const k of ['must_match','must_not_match']) if (c[k]) { try { new RegExp(c[k]); } catch (e) { errors.push(`${rel}: 正規表達式錯誤 ${c[k]}`); } }
  if (!chapters.has(d.chapter)) errors.push(`${rel}: 警告：找不到章節 ${d.chapter} 的課文`);
  if (!d.hints || d.hints.length === 0) if (!['xcode','flash'].includes(d.type)) errors.push(`${rel}: 警告：沒有 hints`);
}
console.log(errors.length ? errors.join('\n') : '全部通過'); console.log(`課文 ${chapters.size} 章、題目 ${ids.size} 題`);
process.exit(errors.some(e => !e.includes('警告')) ? 1 : 0);
