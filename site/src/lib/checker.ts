// 網頁端靜態驗證器：比正規表達式嚴謹、比編譯器寬鬆。抓不到型別錯誤與找不到的 selector。
export interface Check {
  must_match?: string; must_not_match?: string; contains?: string; not_contains?: string;
  selector_equals?: string; selector_present?: string; brackets_balanced?: boolean; property_attrs?: { name: string; attrs: string[] };
  message?: string;
}
export interface CheckResult { ok: boolean; failures: string[] }

export function normalize(src: string): string {
  return src.replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/.*$/gm, '').replace(/[\u201C\u201D]/g, '"').replace(/\s+/g, ' ').trim();
}
export function bracketsBalanced(src: string): boolean {
  const s = src.replace(/"(?:\\.|[^"\\])*"/g, '""').replace(/'(?:\\.|[^'\\])*'/g, "''");
  const stack: string[] = []; const pairs: Record<string, string> = { ')': '(', ']': '[', '}': '{' };
  for (const ch of s) { if ('([{'.includes(ch)) stack.push(ch); else if (ch in pairs) { if (stack.pop() !== pairs[ch]) return false; } }
  return stack.length === 0;
}
// 解析方法宣告：- (void)addAmount:(NSDecimalNumber *)amount note:(NSString *)note
export function selectors(src: string): string[] {
  const out: string[] = []; const n = normalize(src);
  const re = /[-+]\s*\(([^)]*)\)\s*([A-Za-z_][\w]*(?:\s*:\s*\([^)]*\)\s*[A-Za-z_]\w*\s*(?:[A-Za-z_]\w*\s*:\s*\([^)]*\)\s*[A-Za-z_]\w*\s*)*)?)/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(n))) {
    const sig = m[2];
    if (!sig.includes(':')) { out.push(sig.trim()); continue; }
    const parts = sig.match(/[A-Za-z_]\w*\s*:/g) || [];
    out.push(parts.map(p => p.replace(/\s/g, '')).join(''));
  }
  return out;
}
export function propertyAttrs(src: string, name: string): string[] | null {
  const re = new RegExp(`@property\\s*\\(([^)]*)\\)[^;]*\\b${name}\\s*;`); const m = normalize(src).match(re);
  return m ? m[1].split(',').map(s => s.trim().split('=')[0].trim()) : null;
}
export function runChecks(src: string, checks: Check[]): CheckResult {
  const failures: string[] = []; const n = normalize(src); const sels = selectors(src);
  for (const c of checks) {
    const msg = c.message;
    if (c.brackets_balanced && !bracketsBalanced(src)) failures.push(msg || '括號 ( ) [ ] { } 沒有成對。');
    if (c.must_match && !new RegExp(c.must_match, 'm').test(n)) failures.push(msg || `缺少必要的結構：${c.must_match}`);
    if (c.must_not_match && new RegExp(c.must_not_match, 'm').test(n)) failures.push(msg || `出現了不該有的寫法：${c.must_not_match}`);
    if (c.contains && !n.includes(c.contains)) failures.push(msg || `缺少：${c.contains}`);
    if (c.not_contains && n.includes(c.not_contains)) failures.push(msg || `不應出現：${c.not_contains}`);
    if (c.selector_equals && !sels.includes(c.selector_equals)) failures.push(msg || `找不到方法 ${c.selector_equals}（目前解析到：${sels.join(', ') || '無'}）`);
    if (c.selector_present && !sels.some(s => s.includes(c.selector_present!))) failures.push(msg || `找不到含 ${c.selector_present} 的方法`);
    if (c.property_attrs) { const a = propertyAttrs(src, c.property_attrs.name); if (!a) failures.push(msg || `找不到屬性 ${c.property_attrs.name}`); else for (const want of c.property_attrs.attrs) if (!a.includes(want)) failures.push(msg || `屬性 ${c.property_attrs.name} 缺少修飾詞 ${want}`); }
  }
  return { ok: failures.length === 0, failures };
}
