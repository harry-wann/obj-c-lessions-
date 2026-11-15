import { useEffect, useState } from 'preact/hooks';
import { load, type Progress } from '../lib/progress';
interface Lesson { id: string; title: string; chapter: string; href: string }
interface ExMeta { id: string; title: string; chapter: string; href: string; type: string }
export default function HomeDash({ lessons, exercises, total }: { lessons: Lesson[]; exercises: ExMeta[]; total: number }) {
  const [p, setP] = useState<Progress | null>(null);
  useEffect(() => { const s = () => setP(load()); s(); addEventListener('lb-progress', s); return () => removeEventListener('lb-progress', s); }, []);
  if (!p) return <div class="card p-4 muted">載入進度…</div>;
  const doneCount = Object.values(p.chapters).filter(c => c.done).length;
  const last = lessons.find(l => l.id === p.lastLesson);
  const next = (() => { const i = last ? lessons.findIndex(l => l.id === last.id) : -1; return lessons.slice(i + 1).find(l => !p.chapters[l.id]?.done) || lessons.find(l => !p.chapters[l.id]?.done); })();
  const now = Date.now();
  const review = exercises.filter(e => { const r = p.exercises[e.id]; return r && e.type !== 'xcode' && (r.status === 'fail' || (r.nextReviewAt && Date.parse(r.nextReviewAt) <= now)); }).slice(0, 5);
  const todo = p.macTodo.map(id => exercises.find(e => e.id === id)).filter(Boolean) as ExMeta[];
  return (
    <div class="space-y-3">
      <div class="card p-4">
        <div class="flex items-center justify-between"><div class="font-bold">總進度</div><div class="text-sm muted">{doneCount} / {total} 章</div></div>
        <div class="progress mt-2"><div style={{ width: `${total ? (doneCount / total) * 100 : 0}%` }} /></div>
        {next && <a href={next.href} class="btn mt-3 w-full no-underline">{last && !p.chapters[last.id]?.done ? '繼續' : '下一章'}：{next.chapter} {next.title}</a>}
        {!next && total > 0 && <div class="mt-3 text-[color:var(--color-income)] font-semibold">目前上線的章節都完成了 🎉</div>}
      </div>
      {todo.length > 0 && <div class="card p-4"><div class="font-bold mb-1">💻 回 Mac 待辦（{todo.length}）</div><ul class="space-y-1 text-[0.9375rem]">{todo.map(t => <li><a href={t.href} class="no-underline">{t.chapter} · {t.title}</a></li>)}</ul></div>}
      <div class="card p-4"><div class="font-bold mb-1">🔁 今日複習（{review.length}）</div>
        {review.length === 0 ? <div class="muted text-sm">目前沒有待複習的題目。答錯的題與到期的題會出現在這裡。</div> : <ul class="space-y-1 text-[0.9375rem]">{review.map(t => <li><a href={t.href} class="no-underline">{t.chapter} · {t.title}</a></li>)}</ul>}
      </div>
    </div>
  );
}
