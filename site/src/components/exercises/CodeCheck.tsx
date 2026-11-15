import { md } from './md';
import { useRef, useState } from 'preact/hooks';
import { Hints, Result, useAttempts, SymbolBar } from './common';
import { runChecks, type Check } from '../../lib/checker';
export interface CodeData { id: string; starter?: string; checks: Check[]; hints: string[]; solution?: string; solution_note?: string }
export default function CodeCheck({ ex }: { ex: CodeData }) {
  const [val, setVal] = useState(ex.starter || '');
  const [fails, setFails] = useState<string[]>([]);
  const { attempts, ok, submit } = useAttempts(ex.id);
  const ref = useRef<HTMLTextAreaElement>(null);
  const check = () => { const r = runChecks(val, ex.checks); setFails(r.failures); submit(r.ok); };
  return (
    <div>
      <div class="text-sm muted mb-1">在下方輸入程式碼。網頁驗證器只檢查結構與慣例，抓不到型別錯誤；通過後請貼進 Scratch 專案真的編譯一次。手機上建議只寫簽名，整段回 Mac 寫。</div>
      <textarea ref={ref} class="code" value={val} onInput={e => setVal((e.target as HTMLTextAreaElement).value)} autocapitalize="off" autocorrect="off" spellcheck={false} />
      <SymbolBar target={() => ref.current} />
      <div class="mt-2 flex gap-2"><button type="button" class="btn small" disabled={!val.trim() || ok === true} onClick={check}>檢查</button><button type="button" class="btn small secondary" onClick={() => setVal(ex.starter || '')}>重設</button></div>
      <Result ok={ok} />
      {ok === false && fails.length > 0 && <ul class="mt-2 text-sm list-disc ml-5 text-[color:var(--color-expense)]">{fails.map(f => <li>{f}</li>)}</ul>}
      {ok && ex.solution && <details class="fold card p-3 mt-3" open><summary>參考解答與逐行說明</summary><pre class="code-plain mt-2" style="white-space:pre-wrap">{ex.solution}</pre>{ex.solution_note && <div class="mt-2 text-[0.9375rem]">{md(ex.solution_note)}</div>}</details>}
      {!ok && <Hints hints={ex.hints} attempts={attempts} solution={attempts >= 3 ? `${ex.solution || ''}\n\n${ex.solution_note || ''}` : undefined} />}
    </div>
  );
}
