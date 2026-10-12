"use client";
import { useState } from "react";
import useAccountQuery from "@/components/account/useAccountQuery";
import { displayDate, type PointEntry } from "@/service/accountService";
import type { PageResponse } from "@/type/api";

const today = () => new Intl.DateTimeFormat("en-CA", { timeZone: "Asia/Ho_Chi_Minh", year: "numeric", month: "2-digit", day: "2-digit" }).format(new Date());
function monthsBefore(date: string, months: number) {
  const [year, month, day] = date.split("-").map(Number);
  const target = new Date(Date.UTC(year, month - 1 - months, 1));
  const max = new Date(Date.UTC(target.getUTCFullYear(), target.getUTCMonth() + 1, 0)).getUTCDate();
  target.setUTCDate(Math.min(day, max)); return target.toISOString().slice(0, 10);
}
export default function PointHistory({ version }: { version: number }) {
  const [range, setRange] = useState(() => { const to = today(); return { from: monthsBefore(to, 1), to }; });
  const [preset, setPreset] = useState("1"); const [page, setPage] = useState(0); const [retry, setRetry] = useState(0);
  const invalid = !range.from || !range.to || range.from > range.to;
  const { data, loading, error } = useAccountQuery<PageResponse<PointEntry>>(invalid ? null : `/me/loyalty/history?from=${range.from}&to=${range.to}&page=${page}&size=10`, version + retry);
  return <section><div className="flex flex-wrap justify-between items-center gap-3 mb-4"><h2 className="font-bold text-lg">Lịch sử điểm</h2>
    <select aria-label="Khoảng thời gian" value={preset} className="border rounded px-3 py-2 text-xs" onChange={event => {
      const value = event.target.value; setPreset(value); setPage(0);
      if (value !== "custom") { const to = today(); setRange({ from: monthsBefore(to, Number(value)), to }); }
    }}><option value="1">1 tháng gần nhất</option><option value="3">3 tháng gần nhất</option><option value="6">6 tháng gần nhất</option><option value="custom">Tùy chọn</option></select></div>
    {preset === "custom" && <div className="flex gap-3 mb-4 text-xs"><label>Từ ngày<input type="date" className="block border rounded px-2 py-1 mt-1" value={range.from} onChange={event => { setRange({ ...range, from: event.target.value }); setPage(0); }} /></label>
      <label>Đến ngày<input type="date" className="block border rounded px-2 py-1 mt-1" value={range.to} onChange={event => { setRange({ ...range, to: event.target.value }); setPage(0); }} /></label></div>}
    {invalid ? <p role="alert" className="text-sm text-red-600">Chọn khoảng thời gian hợp lệ.</p> : loading ? <div aria-label="Đang tải lịch sử điểm" className="h-40 bg-gray-100 animate-pulse rounded-lg" />
      : error ? <p role="alert" className="text-sm">{error}<button className="underline ml-3" onClick={() => setRetry(value => value + 1)}>Thử lại</button></p>
        : !data?.content.length ? <p className="text-sm text-gray-500 py-8 text-center border rounded-lg">Chưa có giao dịch điểm trong khoảng thời gian này.</p>
          : <ul className="border rounded-lg divide-y divide-gray-100">{data.content.map(entry => <li key={entry.id} className="flex justify-between items-center gap-4 px-4 py-3">
            <div><strong className={`text-sm ${entry.points > 0 ? "text-green-700" : "text-gray-900"}`}>{entry.points > 0 ? "+" : ""}{entry.points.toLocaleString("vi-VN")} điểm</strong>
              <p className="text-xs text-gray-500 mt-1">{entry.description}</p></div><div className="text-right text-xs text-gray-500"><time>{displayDate(entry.createdAt)}</time><p className="mt-1">Số dư {entry.balanceAfter.toLocaleString("vi-VN")}</p></div></li>)}</ul>}
    {data && data.totalPages > 1 && <div className="flex justify-end items-center gap-4 mt-4 text-xs"><button disabled={page === 0} className="border rounded px-3 py-2 disabled:opacity-40" onClick={() => setPage(value => value - 1)}>Trước</button>
      <span>{page + 1} / {data.totalPages}</span><button disabled={page + 1 >= data.totalPages} className="border rounded px-3 py-2 disabled:opacity-40" onClick={() => setPage(value => value + 1)}>Sau</button></div>}
  </section>;
}
