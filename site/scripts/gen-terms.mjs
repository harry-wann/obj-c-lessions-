// 從 docs/06-術語對照表.md 產生 src/data/terms.json
import { readFileSync, writeFileSync } from 'node:fs';
const md = readFileSync(new URL('../../docs/06-術語對照表.md', import.meta.url), 'utf8');
const out = []; let section = '';
for (const line of md.split('\n')) {
  const h = line.match(/^## (.+)/); if (h) { section = h[1]; continue; }
  if (!line.startsWith('|') || /^\|\s*英文/.test(line) || /^\|---/.test(line)) continue;
  const cells = line.split('|').slice(1, -1).map(s => s.trim());
  if (cells.length < 4 || section.startsWith('寫作')) continue;
  const [en, tw, cn, jp, note = ''] = cells;
  out.push({ section, en, tw: tw.replace(' ★', ''), star: tw.includes('★'), cn, jp, note });
}
writeFileSync(new URL('../src/data/terms.json', import.meta.url), JSON.stringify(out, null, 1));
console.log('terms:', out.length);
