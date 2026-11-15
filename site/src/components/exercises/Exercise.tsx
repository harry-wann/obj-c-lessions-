import Quiz from './Quiz'; import FillBlank from './FillBlank'; import Parsons from './Parsons'; import Predict from './Predict'; import SpotBug from './SpotBug'; import CrashRead from './CrashRead'; import CodeCheck from './CodeCheck'; import XcodeTask from './XcodeTask'; import Flash from './Flash';
import { useRecord } from './common';
import { md } from './md';
export const TYPE_LABEL: Record<string, string> = { quiz: '選擇', fill: '填空', parsons: '排序', predict: '預測輸出', spot: '找錯', crash: '讀崩潰訊息', code: '寫程式', xcode: 'Xcode 任務', flash: '速記卡' };
export const TIER_LABEL: Record<string, string> = { basic: '基礎', advanced: '進階', interview: '面試等級' };
export default function Exercise({ ex, index }: { ex: any; index?: number }) {
  const rec = useRecord(ex.id);
  const Comp = ({ quiz: Quiz, fill: FillBlank, parsons: Parsons, predict: Predict, spot: SpotBug, crash: CrashRead, code: CodeCheck, xcode: XcodeTask, flash: Flash } as Record<string, any>)[ex.type];
  const isXcode = ex.type === 'xcode';
  return (
    <section id={`ex-${ex.id}`} class="card p-4 my-3 border-[0.5px] border-[color:var(--line)]">
      <div class="flex flex-wrap items-center gap-x-2 gap-y-1 text-xs muted mb-1">
        <span class={`rounded-md px-1.5 py-0.5 font-semibold ${isXcode ? 'bg-[color:var(--color-cat)]/15 text-[color:var(--color-cat)]' : 'bg-[color:var(--color-tint)]/15 text-[color:var(--color-tint)]'}`}>{isXcode ? '💻 Xcode' : '🌐 網頁'} · {TYPE_LABEL[ex.type]}</span>
        {ex.tier && ex.tier !== 'basic' && <span class="rounded-md px-1.5 py-0.5 bg-[color:var(--color-warn)]/15 text-[color:var(--color-warn)] font-semibold">{TIER_LABEL[ex.tier]}</span>}
        {!isXcode && ex.mobile === false && <span>建議在 Mac 上做</span>}
        <span>⏱ {ex.minutes} 分</span>
        {rec?.status === 'pass' && <span class="text-[color:var(--color-income)] font-semibold">✓ 已通過</span>}
        {rec?.status === 'fail' && <span class="text-[color:var(--color-expense)]">答錯過 · 在複習池</span>}
      </div>
      <h4 class="font-bold text-[1.0625rem] mb-1">{index != null ? `${index}. ` : ''}{ex.title}</h4>
      {ex.prompt && <div class="text-[0.9375rem] mb-2">{md(ex.prompt)}</div>}
      {Comp ? <Comp ex={ex} /> : <div class="muted">未知題型 {ex.type}</div>}
    </section>
  );
}
