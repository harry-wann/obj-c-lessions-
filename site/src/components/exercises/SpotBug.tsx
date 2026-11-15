import { md } from './md';
import { useState } from 'preact/hooks';
import { Hints, Result, useAttempts } from './common';
export interface SpotData { id: string; code: string; bug_lines: number[]; reasons: string[]; answer_reason: number; hints: string[]; fix?: string; solution_note?: string; feedback?: Record<string, string> }
export default function SpotBug({ ex }: { ex: SpotData }) {
  const lines = ex.code.replace(/\n$/, '').split('\n');
  const [sel, setSel] = useState<Set<number>>(new Set());
  const [reason, setReason] = useState<number | null>(null);
  const { attempts, ok, submit } = useAttempts(ex.id);
  const [fb, setFb] = useState<string | undefined>();
  const check = () => { const target = new Set(ex.bug_lines); const linesOk = sel.size === target.size && [...sel].every(l => target.has(l)); const rOk = reason === ex.answer_reason; setFb(!rOk && reason != null ? ex.feedback?.[String(reason)] : undefined); submit(linesOk && rOk); };
  return (
    <div>
      <div class="text-sm muted mb-1">① 點選有問題的行（可多行）　② 選出原因</div>
      <div class="code-plain lines" style="padding:0.5rem 0.25rem">{lines.map((l, i) => { const n = i + 1; return <button type="button" class={`${sel.has(n) ? 'selected' : ''} ${ok && ex.bug_lines.includes(n) ? 'correct' : ''}`} onClick={() => { const s = new Set(sel); s.has(n) ? s.delete(n) : s.add(n); setSel(s); }}>{l || ' '}</button>; })}</div>
      <div class="mt-2 space-y-2">{ex.reasons.map((r, i) => <button type="button" onClick={() => setReason(i)} class={`w-full text-left rounded-xl px-3 py-2 min-h-11 border-[1.5px] ${reason === i ? 'border-[color:var(--color-tint)] bg-[color:var(--color-tint)]/10' : 'border-[color:var(--line)]'}`}><span class="muted mr-2 font-mono text-sm">{String.fromCharCode(65 + i)}</span>{md(r)}</button>)}</div>
      <div class="mt-3"><button type="button" class="btn small" disabled={sel.size === 0 || reason == null || ok === true} onClick={check}>檢查</button></div>
      <Result ok={ok} />
      {ok && (ex.fix || ex.solution_note) && <div class="callout tip mt-3"><div class="callout-title">修法</div>{ex.fix && <pre class="code-plain" style="white-space:pre-wrap">{ex.fix}</pre>}{ex.solution_note && <div>{md(ex.solution_note)}</div>}</div>}
      {!ok && <Hints hints={ex.hints} attempts={attempts} feedback={fb} solution={attempts >= 3 ? `有問題的行：${ex.bug_lines.join('、')}；原因：${String.fromCharCode(65 + ex.answer_reason)}。\n${ex.fix || ''}` : undefined} />}
    </div>
  );
}
