export type ExStatus = 'pass' | 'fail' | 'todo';
export interface ExRecord { status: ExStatus; attempts: number; lastAt: string; passes?: number; nextReviewAt?: string }
export interface Progress {
  version: 1;
  chapters: Record<string, { done: boolean; doneAt?: string }>;
  exercises: Record<string, ExRecord>;
  macTodo: string[];
  lastLesson?: string;
  settings: { fontScale: number; wrapCode: boolean; theme: 'system' | 'light' | 'dark' };
}
const KEY = 'lb-progress-v1';
const empty = (): Progress => ({ version: 1, chapters: {}, exercises: {}, macTodo: [], settings: { fontScale: 1, wrapCode: false, theme: 'system' } });

export function load(): Progress {
  if (typeof localStorage === 'undefined') return empty();
  try { const raw = localStorage.getItem(KEY); if (!raw) return empty(); const p = JSON.parse(raw); return { ...empty(), ...p, settings: { ...empty().settings, ...(p.settings || {}) } }; } catch { return empty(); }
}
export function save(p: Progress) { try { localStorage.setItem(KEY, JSON.stringify(p)); window.dispatchEvent(new CustomEvent('lb-progress')); } catch {} }
export function update(fn: (p: Progress) => void) { const p = load(); fn(p); save(p); return p; }

export function markChapter(id: string, done = true) { update(p => { p.chapters[id] = { done, doneAt: new Date().toISOString() }; }); }
export function setLastLesson(id: string) { update(p => { p.lastLesson = id; }); }
export function recordExercise(id: string, pass: boolean) {
  update(p => {
    const r = p.exercises[id] || { status: 'todo', attempts: 0, lastAt: '', passes: 0 };
    r.attempts += 1; r.lastAt = new Date().toISOString();
    if (pass) { r.status = 'pass'; r.passes = (r.passes || 0) + 1; const days = r.passes >= 3 ? 0 : r.passes === 2 ? 5 : 2; r.nextReviewAt = days ? new Date(Date.now() + days * 864e5).toISOString() : undefined; }
    else { r.status = 'fail'; r.passes = 0; r.nextReviewAt = new Date().toISOString(); }
    p.exercises[id] = r;
  });
}
export function toggleMacTodo(id: string) { update(p => { const i = p.macTodo.indexOf(id); if (i >= 0) p.macTodo.splice(i, 1); else p.macTodo.push(id); }); }
export function exportJSON(): string { return JSON.stringify(load(), null, 2); }
export function importJSON(text: string) {
  const inc = JSON.parse(text) as Progress; if (inc.version !== 1) throw new Error('版本不符');
  update(p => {
    for (const [k, v] of Object.entries(inc.chapters || {})) if (!p.chapters[k]?.done || (v.doneAt || '') > (p.chapters[k]?.doneAt || '')) p.chapters[k] = v;
    for (const [k, v] of Object.entries(inc.exercises || {})) if (!p.exercises[k] || v.lastAt > p.exercises[k].lastAt) p.exercises[k] = v;
    p.macTodo = Array.from(new Set([...(p.macTodo || []), ...(inc.macTodo || [])]));
    if (inc.lastLesson) p.lastLesson = inc.lastLesson;
  });
}
export function applySettings(p = load()) {
  const s = p.settings; const html = document.documentElement;
  html.style.setProperty('--fs', String(s.fontScale));
  html.classList.toggle('code-wrap', !!s.wrapCode);
  const theme = s.theme === 'system' ? (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light') : s.theme;
  html.setAttribute('data-theme', theme);
}
