import { useEffect, useState } from 'preact/hooks';
import { load, recordExercise, type ExRecord } from '../../lib/progress';
import { md } from './md';

export const SYMBOLS = ['[', ']', '{', '}', '(', ')', '@', ';', '*', '^', ':', '-', '"', '_', '<', '>', '=', '%'];

export function SymbolBar({ target }: { target: () => HTMLTextAreaElement | HTMLInputElement | null }) {
  const insert = (s: string) => {
    const el = target(); if (!el) return;
    const start = el.selectionStart ?? el.value.length, end = el.selectionEnd ?? el.value.length;
    el.value = el.value.slice(0, start) + s + el.value.slice(end);
    el.selectionStart = el.selectionEnd = start + s.length;
    el.dispatchEvent(new Event('input', { bubbles: true })); el.focus();
  };
  return <div class="symbar" aria-label="符號快捷列">{SYMBOLS.map(s => <button type="button" onClick={() => insert(s)}>{s}</button>)}</div>;
}

export function useRecord(id: string) {
  const [rec, setRec] = useState<ExRecord | undefined>(undefined);
  useEffect(() => { setRec(load().exercises[id]); const h = () => setRec(load().exercises[id]); addEventListener('lb-progress', h); return () => removeEventListener('lb-progress', h); }, [id]);
  return rec;
}

/** 提示階梯：第 1 次錯 → 提示 1；第 2 次 → 提示 2 + 針對性回饋；第 3 次 → 可看解答 */
export function Hints({ hints, attempts, feedback, solution, children }: { hints: string[]; attempts: number; feedback?: string; solution?: string; children?: any }) {
  if (attempts === 0) return null;
  const n = Math.min(attempts, hints.length);
  return (
    <div class="mt-3 text-[0.9375rem] space-y-2">
      {feedback && <div class="callout pitfall" style="margin:0"><div class="callout-title">針對你的答案</div>{md(feedback)}</div>}
      {hints.slice(0, n).map((h, i) => <div class="callout tip" style="margin:0"><div class="callout-title">提示 {i + 1}</div>{md(h)}</div>)}
      {attempts >= 3 && (solution || children) && <details class="fold card p-3"><summary>參考解答</summary><div class="mt-2">{solution && <div>{md(solution)}</div>}{children}</div></details>}
    </div>
  );
}

export function Result({ ok, text }: { ok: boolean | null; text?: string }) {
  if (ok === null) return null;
  return <div class={`mt-3 rounded-xl px-3 py-2 font-semibold ${ok ? 'bg-[color:var(--color-income)]/15 text-[color:var(--color-income)]' : 'bg-[color:var(--color-expense)]/15 text-[color:var(--color-expense)]'}`}>{ok ? '✓ 正確' : '✗ 再試一次'}{text ? `：${text}` : ''}</div>;
}

export function useAttempts(id: string) {
  const [attempts, setAttempts] = useState(0);
  const [ok, setOk] = useState<boolean | null>(null);
  const submit = (pass: boolean) => { setOk(pass); if (!pass) setAttempts(a => a + 1); recordExercise(id, pass); };
  return { attempts, ok, submit, reset: () => { setOk(null); } };
}

export function Code({ code, lang = 'objc' }: { code: string; lang?: string }) {
  return <pre class="code-plain" data-lang={lang}>{code}</pre>;
}

export function shuffle<T>(arr: T[], seed = 1): T[] {
  const a = arr.slice(); let s = seed * 9301 + 49297;
  for (let i = a.length - 1; i > 0; i--) { s = (s * 9301 + 49297) % 233280; const j = Math.floor((s / 233280) * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; }
  return a;
}
