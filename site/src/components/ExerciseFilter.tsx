import { useEffect, useState } from 'preact/hooks';
import { load } from '../lib/progress';
import { TYPE_LABEL } from './exercises/Exercise';
interface Row { id: string; title: string; chapter: string; href: string; type: string; mobile: boolean; tier: string; minutes: number }
export default function ExerciseFilter({ rows }: { rows: Row[] }) {
  const [p, setP] = useState<any>(null); const [kind, setKind] = useState<'all' | 'web' | 'xcode'>('all'); const [status, setStatus] = useState<'all' | 'todo' | 'fail' | 'pass'>('all'); const [tier, setTier] = useState<'main' | 'all'>('main');
  useEffect(() => { const s = () => setP(load()); s(); addEventListener('lb-progress', s); return () => removeEventListener('lb-progress', s); }, []);
  const st = (id: string) => p?.exercises?.[id]?.status || 'todo';
  const list = rows.filter(r => (kind === 'all' || (kind === 'xcode') === (r.type === 'xcode')) && (status === 'all' || st(r.id) === status) && (tier === 'all' || r.tier === 'basic'));
  const groups = new Map<string, Row[]>(); for (const r of list) { if (!groups.has(r.chapter)) groups.set(r.chapter, []); groups.get(r.chapter)!.push(r); }
  const Seg = ({ v, set, opts }: any) => <div class="compare"><div class="tabs">{opts.map(([k, l]: any) => <button type="button" aria-selected={String(v === k)} onClick={() => set(k)}>{l}</button>)}</div></div>;
  return (
    <div>
      <Seg v={kind} set={setKind} opts={[['all', '全部'], ['web', '🌐 網頁'], ['xcode', '💻 Xcode']]} />
      <Seg v={status} set={setStatus} opts={[['all', '全部狀態'], ['todo', '未做'], ['fail', '答錯過'], ['pass', '已通過']]} />
      <Seg v={tier} set={setTier} opts={[['main', '主線'], ['all', '含加練區']]} />
      <div class="muted text-sm my-2">{list.length} 題</div>
      {[...groups.entries()].map(([ch, rs]) => <div class="card p-3 my-2"><div class="font-bold mb-1">{ch}</div><ul class="space-y-1">{rs.map(r => <li class="flex items-center gap-2 text-[0.9375rem] min-h-9"><span class={`text-xs rounded px-1 ${r.type === 'xcode' ? 'bg-[color:var(--color-cat)]/15' : 'bg-[color:var(--color-tint)]/15'}`}>{r.type === 'xcode' ? '💻' : '🌐'} {TYPE_LABEL[r.type]}</span><a href={r.href} class="no-underline flex-1 truncate">{r.title}</a><span class="text-xs">{st(r.id) === 'pass' ? '✓' : st(r.id) === 'fail' ? '✗' : ''}</span></li>)}</ul></div>)}
    </div>
  );
}
