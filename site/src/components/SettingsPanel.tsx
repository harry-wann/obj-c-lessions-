import { useEffect, useState } from 'preact/hooks';
import { load, update, applySettings, exportJSON, importJSON } from '../lib/progress';
export default function SettingsPanel() {
  const [s, setS] = useState(load().settings); const [msg, setMsg] = useState('');
  useEffect(() => { setS(load().settings); }, []);
  const set = (patch: Partial<typeof s>) => { const p = update(p => { Object.assign(p.settings, patch); }); setS({ ...p.settings }); applySettings(p); };
  const Seg = ({ v, opts, on }: any) => <div class="compare"><div class="tabs">{opts.map(([k, l]: any) => <button type="button" aria-selected={String(v === k)} onClick={() => on(k)}>{l}</button>)}</div></div>;
  return (
    <div class="space-y-4">
      <div class="card p-4"><div class="font-bold mb-2">外觀</div><Seg v={s.theme} opts={[['system', '跟隨系統'], ['light', '淺色'], ['dark', '深色']]} on={(k: any) => set({ theme: k })} /></div>
      <div class="card p-4"><div class="font-bold mb-2">字級</div><Seg v={s.fontScale} opts={[[0.9, 'A−'], [1, 'A'], [1.12, 'A＋'], [1.25, 'A＋＋']]} on={(k: any) => set({ fontScale: k })} /></div>
      <div class="card p-4"><div class="font-bold mb-2">程式碼</div><Seg v={s.wrapCode} opts={[[false, '不換行（可橫向捲動）'], [true, '自動換行']]} on={(k: any) => set({ wrapCode: k })} /></div>
      <div class="card p-4"><div class="font-bold mb-1">進度匯出 / 匯入</div><div class="text-sm muted mb-2">手機 ⇄ Mac 同步：匯出 JSON 用 AirDrop 傳到另一台，再匯入。匯入會合併（以較新的紀錄為準）。</div>
        <div class="flex flex-wrap gap-2">
          <button type="button" class="btn small" onClick={() => { const b = new Blob([exportJSON()], { type: 'application/json' }); const a = document.createElement('a'); a.href = URL.createObjectURL(b); a.download = `objc-progress-${new Date().toISOString().slice(0, 10)}.json`; a.click(); }}>匯出</button>
          <label class="btn small secondary">匯入<input type="file" accept="application/json" class="hidden" onChange={async e => { const f = (e.target as HTMLInputElement).files?.[0]; if (!f) return; try { importJSON(await f.text()); setMsg('已匯入並合併。'); } catch (err: any) { setMsg('匯入失敗：' + err.message); } }} /></label>
          <button type="button" class="btn small secondary" onClick={() => { if (confirm('確定清除全部進度？')) { localStorage.removeItem('lb-progress-v1'); location.reload(); } }}>清除進度</button>
        </div>{msg && <div class="text-sm mt-2">{msg}</div>}</div>
    </div>
  );
}
