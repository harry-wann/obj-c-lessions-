"""為 YAML（題目檔與 MDX frontmatter）中含「: 」或「 #」的 plain scalar 自動加雙引號。只處理單行值。"""
import re, sys, pathlib
SAFE_START = ('"', "'", '{', '[', '|', '>', '&', '*', '!')
def q(v):
    return '"' + v.replace('\\', '\\\\').replace('"', '\\"') + '"'
def needs(v):
    v = v.strip()
    if not v or v.startswith(SAFE_START): return False
    return ': ' in v or ' #' in v or v.endswith(':') or v.startswith(('@', '`', '%', '-  ')) or v.startswith(('? ',))
def fix_lines(lines):
    out = []; in_block = None
    for line in lines:
        ind = len(line) - len(line.lstrip(' '))
        if in_block is not None:
            if line.strip() == '' or ind > in_block: out.append(line); continue
            in_block = None
        m = re.match(r'^(\s*)([A-Za-z_][\w-]*|"[^"]+"):\s(.*)$', line)
        if m:
            k, v = m.group(2), m.group(3)
            if v.strip() in ('|', '>', '|-', '>-', '|+'): in_block = ind
            elif needs(v): line = f'{m.group(1)}{k}: {q(v.strip())}'
            out.append(line); continue
        m = re.match(r'^(\s*-\s)(.*)$', line)
        if m and not re.match(r'^[A-Za-z_][\w-]*:\s', m.group(2)):
            v = m.group(2)
            if v.strip() in ('|', '>', '|-', '>-'): in_block = ind
            elif needs(v): line = m.group(1) + q(v.strip())
        out.append(line)
    return out
changed = 0
for p in map(pathlib.Path, sys.argv[1:]):
    s = p.read_text()
    if p.suffix == '.mdx':
        m = re.match(r'^---\n([\s\S]*?)\n---', s)
        if not m: continue
        new = '---\n' + '\n'.join(fix_lines(m.group(1).split('\n'))) + '\n---' + s[m.end():]
    else:
        new = '\n'.join(fix_lines(s.split('\n')))
    if new != s: p.write_text(new); changed += 1; print('fixed', p)
print('changed', changed)
