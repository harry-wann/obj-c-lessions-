import { useEffect, useState } from 'preact/hooks';
import { load, markChapter, setLastLesson } from '../lib/progress';
export default function ChapterDone({ id, nextHref, nextTitle }: { id: string; nextHref?: string; nextTitle?: string }) {
  const [done, setDone] = useState(false);
  useEffect(() => { setLastLesson(id); const s = () => setDone(!!load().chapters[id]?.done); s(); addEventListener('lb-progress', s); return () => removeEventListener('lb-progress', s); }, [id]);
  return (
    <div class="flex flex-col gap-2 mt-4">
      <button type="button" class={`btn ${done ? 'secondary' : ''}`} onClick={() => markChapter(id, !done)}>{done ? '✓ 已完成本章（點擊取消）' : '標記本章完成'}</button>
      {nextHref && <a href={nextHref} class="btn secondary no-underline">下一章：{nextTitle} →</a>}
    </div>
  );
}
