import { md } from './md';
import { useEffect, useState } from 'preact/hooks';
import { load, recordExercise, toggleMacTodo } from '../../lib/progress';
export interface XcodeData { id: string; starter?: string; tests?: string[]; acceptance?: string[]; steps?: string[]; solution_note?: string }
export default function XcodeTask({ ex }: { ex: XcodeData }) {
  const items = [...(ex.tests || []).map(t => ({ k: 't:' + t, label: t, kind: '測試' })), ...(ex.acceptance || []).map(a => ({ k: 'a:' + a, label: a, kind: '驗收' }))];
  const [checked, setChecked] = useState<Set<string>>(new Set());
  const [todo, setTodo] = useState(false); const [done, setDone] = useState(false);
  const key = `lb-xc-${ex.id}`;
  useEffect(() => { try { setChecked(new Set(JSON.parse(localStorage.getItem(key) || '[]'))); } catch {} const sync = () => { const p = load(); setTodo(p.macTodo.includes(ex.id)); setDone(p.exercises[ex.id]?.status === 'pass'); }; sync(); addEventListener('lb-progress', sync); return () => removeEventListener('lb-progress', sync); }, [ex.id]);
  const toggle = (k: string) => { const s = new Set(checked); s.has(k) ? s.delete(k) : s.add(k); setChecked(s); try { localStorage.setItem(key, JSON.stringify([...s])); } catch {} };
  const all = items.length > 0 && items.every(i => checked.has(i.k));
  return (
    <div>
      {ex.starter && <div class="text-sm mb-2">起始專案：<code class="font-mono">{ex.starter}</code></div>}
      {ex.steps && ex.steps.length > 0 && <ol class="list-decimal ml-5 text-[0.9375rem] space-y-1 mb-2">{ex.steps.map(s => <li>{md(s)}</li>)}</ol>}
      <div class="space-y-1">{items.map(i => <label class="flex items-start gap-2 min-h-11 py-1"><input type="checkbox" class="mt-1.5 w-5 h-5" checked={checked.has(i.k)} onChange={() => toggle(i.k)} /><span><span class="text-xs muted mr-1">{i.kind}</span><span class="font-mono text-[0.875rem] break-all">{i.label}</span></span></label>)}</div>
      <div class="mt-3 flex flex-wrap gap-2">
        <button type="button" class={`btn small ${todo ? '' : 'secondary'}`} onClick={() => toggleMacTodo(ex.id)}>{todo ? '✓ 已加入回 Mac 待辦' : '加入回 Mac 待辦'}</button>
        <button type="button" class="btn small" disabled={!all || done} onClick={() => { recordExercise(ex.id, true); if (todo) toggleMacTodo(ex.id); }}>{done ? '✓ 已完成' : '全部通過，標記完成'}</button>
      </div>
      {ex.solution_note && <div class="muted text-sm mt-2">{md(ex.solution_note)}</div>}
    </div>
  );
}
