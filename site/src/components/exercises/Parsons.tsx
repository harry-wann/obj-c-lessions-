import { md } from './md';
import { useMemo, useState } from 'preact/hooks';
import { Hints, Result, useAttempts, shuffle } from './common';
export interface ParsonsData { id: string; lines: string[]; distractors?: string[]; hints: string[]; solution_note?: string }
export default function Parsons({ ex }: { ex: ParsonsData }) {
  const pool = useMemo(() => shuffle([...ex.lines, ...(ex.distractors || [])].map((t, i) => ({ t, i })), ex.id.length), [ex.id]);
  const [picked, setPicked] = useState<number[]>([]);
  const { attempts, ok, submit } = useAttempts(ex.id);
  const avail = pool.filter(p => !picked.includes(p.i));
  const check = () => { const ans = picked.map(i => pool.find(p => p.i === i)!.t); submit(ans.length === ex.lines.length && ans.every((l, k) => l === ex.lines[k])); };
  return (
    <div>
      <div class="text-sm muted mb-1">點選下方的行，依正確順序排進上方。{ex.distractors?.length ? '其中有干擾行不該用。' : ''}</div>
      <div class="code-plain min-h-[4rem]" style="white-space: pre-wrap">{picked.length === 0 && <span class="muted">（尚未選擇）</span>}{picked.map((i, k) => <button type="button" class={`block w-full text-left font-mono ${ok === false && pool.find(p => p.i === i)!.t !== ex.lines[k] ? 'text-[color:var(--color-expense)]' : ''}`} onClick={() => setPicked(picked.filter(x => x !== i))}><span class="muted mr-2">{k + 1}.</span>{pool.find(p => p.i === i)!.t}</button>)}</div>
      <div class="mt-2 space-y-1">{avail.map(p => <button type="button" class="block w-full text-left font-mono text-[0.8125rem] rounded-lg px-2 py-1.5 min-h-10 border-[0.5px] border-[color:var(--line)] card whitespace-pre" onClick={() => setPicked([...picked, p.i])}>{p.t}</button>)}</div>
      <div class="mt-3 flex gap-2"><button type="button" class="btn small" disabled={picked.length === 0 || ok === true} onClick={check}>檢查</button><button type="button" class="btn small secondary" onClick={() => setPicked([])}>重排</button></div>
      <Result ok={ok} />
      {ok && ex.solution_note && <div class="callout tip mt-3"><div class="callout-title">說明</div><div>{md(ex.solution_note)}</div></div>}
      {!ok && <Hints hints={ex.hints} attempts={attempts} solution={attempts >= 3 ? ex.lines.join('\n') : undefined} />}
    </div>
  );
}
