"use client";
import { useState } from "react";
import Notification from "@/utils/Notification";
import { redeemReward, type RewardOffer } from "@/service/accountService";
import { money } from "@/cart/types";

export default function RewardExchange({ balance, rewards, onRedeemed }: { balance: number; rewards: RewardOffer[]; onRedeemed: () => void }) {
  const [selected, setSelected] = useState<{ offer: RewardOffer; key: string } | null>(null);
  return <section className="mb-8"><h2 className="font-bold text-lg mb-3">Đổi ưu đãi</h2>
    <p className="text-xs text-gray-500 mb-4">Voucher dùng một lần, có hiệu lực 30 ngày sau khi đổi.</p>
    {!rewards.length && <p className="text-sm text-gray-500">Chưa có ưu đãi để đổi.</p>}
    <div className="grid sm:grid-cols-2 gap-3">{rewards.map(offer => <article key={offer.id} className="border border-gray-200 rounded-lg px-4 py-3">
      <h3 className="text-sm font-semibold">{offer.name}</h3><p className="text-xs text-gray-500 mt-1">{offer.minimum > 0 ? `Đơn từ ${money(offer.minimum)}` : "Không yêu cầu giá trị đơn tối thiểu"}{offer.cap ? ` · Giảm tối đa ${money(offer.cap)}` : ""}</p>
      <div className="flex items-center justify-between gap-3 mt-4"><strong className="text-sm">{offer.points.toLocaleString("vi-VN")} điểm</strong>
        <button disabled={balance < offer.points} className="text-xs font-semibold border rounded px-3 py-2 disabled:text-gray-400 disabled:cursor-not-allowed" onClick={() => setSelected({ offer, key: crypto.randomUUID() })}>{balance < offer.points ? "Chưa đủ điểm" : "Đổi ngay"}</button></div>
    </article>)}</div>
    <Notification open={!!selected} title="Đổi ưu đãi" message={`Dùng ${selected?.offer.points.toLocaleString("vi-VN") ?? ""} điểm để đổi ${selected?.offer.name ?? ""}?`}
      confirmText="Đổi ưu đãi" onClose={() => setSelected(null)} onConfirm={async () => { if (selected) { await redeemReward(selected.offer.id, selected.key); onRedeemed(); } }} />
  </section>;
}
