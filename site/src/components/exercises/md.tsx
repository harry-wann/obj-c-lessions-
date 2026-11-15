// 極簡 inline markdown：`code`、**bold**、換行。題目文字用。
import type { ComponentChildren } from 'preact';
export function md(text: unknown): ComponentChildren {
  if (text == null) return null;
  if (typeof text !== 'string') text = String(text);
  const str = text as string;
  const lines = str.split('\n');
  return lines.map((line, li) => {
    const parts: ComponentChildren[] = []; const re = /(`[^`]+`|\*\*[^*]+\*\*)/g; let last = 0; let m: RegExpExecArray | null;
    while ((m = re.exec(line))) { if (m.index > last) parts.push(line.slice(last, m.index)); const t = m[0]; parts.push(t.startsWith('`') ? <code class="font-mono text-[0.875em] rounded px-1" style="background: color-mix(in srgb, var(--fg) 8%, transparent)">{t.slice(1, -1)}</code> : <strong>{t.slice(2, -2)}</strong>); last = m.index + t.length; }
    if (last < line.length) parts.push(line.slice(last));
    return <>{parts}{li < lines.length - 1 && <br />}</>;
  });
}
