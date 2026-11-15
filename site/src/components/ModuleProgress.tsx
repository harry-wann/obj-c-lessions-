import { useEffect, useState } from 'preact/hooks';
import { load } from '../lib/progress';
export default function ModuleProgress({ ids }: { ids: string[] }) {
  const [n, setN] = useState(0);
  useEffect(() => { const s = () => { const p = load(); setN(ids.filter(i => p.chapters[i]?.done).length); }; s(); addEventListener('lb-progress', s); return () => removeEventListener('lb-progress', s); }, [ids.join(',')]);
  return <div class="flex items-center gap-2 text-xs muted"><div class="progress flex-1"><div style={{ width: `${ids.length ? (n / ids.length) * 100 : 0}%` }} /></div><span>{n}/{ids.length}</span></div>;
}
