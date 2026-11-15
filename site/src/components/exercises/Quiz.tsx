import { md } from './md';
import { useState } from 'preact/hooks';
import { Hints, Result, useAttempts, Code } from './common';
export interface QuizData { id: string; prompt: string; code?: string; options: string[]; answer: number | number[]; multi?: boolean; hints: string[]; explain?: string; feedback?: Record<string, string> }
export default function Quiz({ ex }: { ex: QuizData }) {
  const multi = ex.multi || Array.isArray(ex.answer);
  const correct = new Set(Array.isArray(ex.answer) ? ex.answer : [ex.answer]);
  const [sel, setSel] = useState<Set<number>>(new Set());
  const { attempts, ok, submit } = useAttempts(ex.id);
  const [fb, setFb] = useState<string | undefined>();
  const toggle = (i: number) => { const n = new Set(multi ? sel : []); if (n.has(i)) n.delete(i); else n.add(i); setSel(n); };
  const check = () => { const pass = sel.size === correct.size && [...sel].every(i => correct.has(i)); const wrong = [...sel].find(i => !correct.has(i)); setFb(wrong != null ? ex.feedback?.[String(wrong)] : undefined); submit(pass); };
  return (
    <div>
      {ex.code && <Code code={ex.code} />}
      <div class="mt-2 space-y-2">{ex.options.map((o, i) => (
        <button type="button" onClick={() => toggle(i)} class={`w-full text-left rounded-xl px-3 py-2.5 min-h-11 border-[1.5px] ${sel.has(i) ? 'border-[color:var(--color-tint)] bg-[color:var(--color-tint)]/10' : 'border-[color:var(--line)]'} ${ok && correct.has(i) ? 'border-[color:var(--color-income)]' : ''}`}>
          <span class="muted mr-2 font-mono text-sm">{String.fromCharCode(65 + i)}</span><span>{md(o)}</span>
        </button>))}</div>
      <div class="mt-3 flex gap-2"><button type="button" class="btn small" disabled={sel.size === 0 || ok === true} onClick={check}>檢查</button>{multi && <span class="muted text-sm self-center">可複選</span>}</div>
      <Result ok={ok} />
      {ok && ex.explain && <div class="callout tip mt-3"><div class="callout-title">說明</div><div>{md(ex.explain)}</div></div>}
      {!ok && <Hints hints={ex.hints} attempts={attempts} feedback={fb} solution={attempts >= 3 ? `答案：${[...correct].map(i => String.fromCharCode(65 + i)).join('、')}。${ex.explain || ''}` : undefined} />}
    </div>
  );
}
