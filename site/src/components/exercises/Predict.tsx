import { md } from './md';
import { useRef, useState } from 'preact/hooks';
import { Hints, Result, useAttempts, Code, SymbolBar } from './common';
export interface PredictData { id: string; code: string; options?: string[]; accept: string[]; hints: string[]; feedback?: Record<string, string>; solution_note?: string; note?: string }
const norm = (s: string) => s.replace(/\s+/g, ' ').trim();
export default function Predict({ ex }: { ex: PredictData }) {
  const [val, setVal] = useState('');
  const { attempts, ok, submit } = useAttempts(ex.id);
  const [fb, setFb] = useState<string | undefined>();
  const ref = useRef<HTMLInputElement>(null);
  const check = (v = val) => { const pass = ex.accept.some(a => norm(a) === norm(v)); setFb(pass ? undefined : ex.feedback?.[norm(v)]); submit(pass); };
  return (
    <div>
      <Code code={ex.code} />
      <div class="text-sm muted mt-1">這段程式會印出什麼？{ex.note && <span>（{ex.note}）</span>}</div>
      {ex.options ? <div class="mt-2 grid gap-2">{ex.options.map(o => <button type="button" class={`chip justify-start ${val === o ? 'selected' : ''}`} style="border-radius:10px;min-height:44px;white-space:pre-wrap" onClick={() => setVal(o)}>{o}</button>)}</div>
        : <><input ref={ref} class="code mt-2" value={val} onInput={e => setVal((e.target as HTMLInputElement).value)} placeholder="輸出內容（多行用空格分隔）" autocapitalize="off" autocorrect="off" spellcheck={false} /><SymbolBar target={() => ref.current} /></>}
      <div class="mt-3"><button type="button" class="btn small" disabled={!val || ok === true} onClick={() => check()}>檢查</button></div>
      <Result ok={ok} />
      {ok && ex.solution_note && <div class="callout tip mt-3"><div class="callout-title">為什麼</div><div>{md(ex.solution_note)}</div></div>}
      {!ok && <Hints hints={ex.hints} attempts={attempts} feedback={fb} solution={attempts >= 3 ? `${ex.accept[0]}\n\n${ex.solution_note || ''}` : undefined} />}
    </div>
  );
}
