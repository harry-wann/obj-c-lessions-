import { getCollection, type CollectionEntry } from 'astro:content';
import { lessonUrl } from './base';
export type Lesson = CollectionEntry<'lessons'>;
export async function allLessons(): Promise<Lesson[]> {
  const ls = await getCollection('lessons', ({ data }) => !data.draft);
  return ls.sort((a, b) => a.data.module - b.data.module || a.data.order - b.data.order);
}
export async function allExercises() {
  const ex = await getCollection('exercises');
  return ex.map(e => e.data).sort((a, b) => cmpChapter(a.chapter, b.chapter) || a.id.localeCompare(b.id));
}
export function cmpChapter(a: string, b: string) { const [am, ac] = a.split('.').map(Number); const [bm, bc] = b.split('.').map(Number); return am - bm || ac - bc; }
export async function allModules() { const ms = await getCollection('modules'); return ms.map(m => m.data).sort((a, b) => a.number - b.number); }
export const lessonHref = (l: Lesson) => lessonUrl(l.id);
export function exerciseHref(ex: { id: string; chapter: string }, lessons: Lesson[]) { const l = lessons.find(x => x.data.chapter === ex.chapter); return l ? `${lessonUrl(l.id)}#ex-${ex.id}` : '#'; }
