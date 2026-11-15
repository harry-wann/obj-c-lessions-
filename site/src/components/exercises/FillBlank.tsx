import { md } from './md';
import { useRef, useState } from 'preact/hooks';
import { Hints, Result, useAttempts, SymbolBar } from './common';
export interface FillData { id: string; code: string; blanks: Record<string, { accept: string[]; chips?: string[] }>; hints: string[]; feedback?: Record<string, string>; solution_note?: string }
const norm = (s: string) => s.replace(/\s+/g, ' ').trim();
export default function FillBlank({ ex }: { ex: FillData }) {
  const keys = Object.keys(ex.blanks);
  const [vals, setVals] = useState<Record<string, string>>({});
  const [active, setActive] = useState<string>(keys[0]);
  const [wrong, setWrong] = useState<Set<string>>(new Set());
  const { attempts, ok, submit } = useAttempts(ex.id);
  const [fb, setFb] = useState<string | undefined>();
  const inputRef = useRef<HTMLInputElement>(null);
  const parts = ex.code.split(/(___\d+___)/g);
  const check = () => {
    const w = new Set<string>(); let f: string | undefined;
    for (const k of keys) { const v = norm(vals[k] || ''); const okk = ex.blanks[k].accept.some(a => norm(a) === v); if (!okk) { w.add(k); f ??= ex.feedback?.[`${k}=${v}`]; } }
    setWrong(w); setFb(f); submit(w.size === 0);
  };
  const chips = ex.blanks[active]?.chips;
  return (
    <div>
      <pre class="code-plain" style="white-space: pre-wrap">{parts.map(p => { const m = p.match(/^___(\d+)___$/); if (!m) return p; const k = m[1]; const v = vals[k];
        return <button type="button" onClick={() => setActive(k)} class={`inline-block align-baseline rounded-md px-1.5 mx-0.5 min-w-[3.5rem] min-h-[1.6rem] border-b-2 font-mono ${active === k ? 'border-[color:var(--color-tint)] bg-[color:var(--color-tint)]/10' : 'border-[color:var(--fg2)]'} ${ok && !wrong.has(k) ? 'bg-[color:var(--color-income)]/20' : ''} ${wrong.has(k) ? 'bg-[color:var(--color-expense)]/20' : ''}`}>{v || `❶❷❸❹❺❻❼❽❾`[Number(k) - 1] || k}</button>; })}</pre>
      <div class="mt-2 text-sm muted">填空 {active}：{chips ? '點選候選詞，或直接輸入' : '直接輸入'}</div>
      {chips && <div class="flex flex-wrap gap-2 mt-1">{chips.map(c => <button type="button" class={`chip ${vals[active] === c ? 'selected' : ''}`} onClick={() => { setVals({ ...vals, [active]: c }); const i = keys.indexOf(active); if (i < keys.length - 1) setActive(keys[i + 1]); }}>{c}</button>)}</div>}
      <input ref={inputRef} class="code mt-2" value={vals[active] || ''} onInput={e => setVals({ ...vals, [active]: (e.target as HTMLInputElement).value })} placeholder="輸入答案" autocapitalize="off" autocorrect="off" spellcheck={false} />
      <SymbolBar target={() => inputRef.current} />
      <div class="mt-2"><button type="button" class="btn small" disabled={ok === true} onClick={check}>檢查</button></div>
      <Result ok={ok} text={ok === false ? `${wrong.size} 格不對` : undefined} />
      {ok && ex.solution_note && <div class="callout tip mt-3"><div class="callout-title">說明</div><div>{md(ex.solution_note)}</div></div>}
      {!ok && <Hints hints={ex.hints} attempts={attempts} feedback={fb} solution={attempts >= 3 ? keys.map(k => `${k} → ${ex.blanks[k].accept[0]}`).join('\n') + (ex.solution_note ? `\n\n${ex.solution_note}` : '') : undefined} />}
    </div>
  );
}
