import { md } from './md';
import { useState } from 'preact/hooks';
import { recordExercise } from '../../lib/progress';
export interface FlashData { id: string; front: string; back: string }
export default function Flash({ ex }: { ex: FlashData }) {
  const [open, setOpen] = useState(false); const [graded, setGraded] = useState<boolean | null>(null);
  return (
    <div>
      <div class="card border-[0.5px] border-[color:var(--line)] p-4 min-h-24 whitespace-pre-wrap">{md(open ? ex.back : ex.front)}</div>
      {!open ? <button type="button" class="btn small mt-3" onClick={() => setOpen(true)}>翻面</button>
        : graded == null ? <div class="mt-3 flex gap-2"><button type="button" class="btn small secondary" onClick={() => { setGraded(false); recordExercise(ex.id, false); }}>還不熟</button><button type="button" class="btn small" onClick={() => { setGraded(true); recordExercise(ex.id, true); }}>會了</button></div>
        : <div class="muted text-sm mt-3">{graded ? '已記錄：會了，之後會減少出現。' : '已記錄：加入複習池。'}</div>}
    </div>
  );
}
