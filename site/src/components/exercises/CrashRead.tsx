import { md } from './md';
import { useState } from 'preact/hooks';
import { Hints, Result, useAttempts } from './common';
export interface CrashData { id: string; log: string; options: string[]; answer: number; fix?: string; hints: string[]; solution_note?: string; feedback?: Record<string, string> }
export default function CrashRead({ ex }: { ex: CrashData }) {
  const [sel, setSel] = useState<number | null>(null);
  const { attempts, ok, submit } = useAttempts(ex.id);
  const [fb, setFb] = useState<string | undefined>();
  const check = () => { const pass = sel === ex.answer; setFb(pass ? undefined : ex.feedback?.[String(sel)]); submit(pass); };
  return (
    <div>
      <pre class="code-plain text-[color:var(--color-expense)]" style="white-space:pre-wrap;word-break:break-all">{ex.log}</pre>
      <div class="text-sm muted mt-1">最可能的原因是？</div>
      <div class="mt-2 space-y-2">{ex.options.map((r, i) => <button type="button" onClick={() => setSel(i)} class={`w-full text-left rounded-xl px-3 py-2 min-h-11 border-[1.5px] ${sel === i ? 'border-[color:var(--color-tint)] bg-[color:var(--color-tint)]/10' : 'border-[color:var(--line)]'} ${ok && i === ex.answer ? 'border-[color:var(--color-income)]' : ''}`}><span class="muted mr-2 font-mono text-sm">{String.fromCharCode(65 + i)}</span>{md(r)}</button>)}</div>
      <div class="mt-3"><button type="button" class="btn small" disabled={sel == null || ok === true} onClick={check}>檢查</button></div>
      <Result ok={ok} />
      {ok && (ex.fix || ex.solution_note) && <div class="callout tip mt-3"><div class="callout-title">怎麼修</div>{ex.fix && <pre class="code-plain" style="white-space:pre-wrap">{ex.fix}</pre>}{ex.solution_note && <div>{md(ex.solution_note)}</div>}</div>}
      {!ok && <Hints hints={ex.hints} attempts={attempts} feedback={fb} solution={attempts >= 3 ? `答案：${String.fromCharCode(65 + ex.answer)}。${ex.solution_note || ''}` : undefined} />}
    </div>
  );
}
