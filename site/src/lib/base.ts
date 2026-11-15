export const BASE = import.meta.env.BASE_URL.replace(/\/$/, '');
export const url = (p: string) => `${BASE}${p.startsWith('/') ? p : '/' + p}`;
export const lessonUrl = (id: string) => url(`/lessons/${id}`);
