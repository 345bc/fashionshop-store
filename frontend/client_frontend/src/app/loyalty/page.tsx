"use client";
import { useState } from "react";
import useAccountQuery from "@/components/account/useAccountQuery";
import AccountLayout from "@/components/account/AccountLayout";
import { displayDate, utcDate, type RewardOffer, type RewardSummary } from "@/service/accountService";
import type { PageResponse } from "@/type/api";
import RewardExchange from "./RewardExchange";
import PointHistory from "./PointHistory";

export default function LoyaltyPage() {
  const [version, setVersion] = useState(0);
  const { data, loading, error } = useAccountQuery<RewardSummary>("/me/loyalty", version);
  const [now, setNow] = useState(() => Date.now());
  const [voucherOpen, setVoucherOpen] = useState(false); const [notice, setNotice] = useState("");
  const [voucherPage, setVoucherPage] = useState(0);
  const wallet = useAccountQuery<PageResponse<RewardOffer>>(voucherOpen && voucherPage > 0 ? `/me/loyalty/vouchers?page=${voucherPage}&size=10` : null, version);
  const voucherData = voucherPage === 0 ? data?.vouchers : wallet.data;
  return <AccountLayout active="loyalty" title={
    <div className="flex items-center gap-2">
      <span>Điểm thưởng</span>
      <div className="relative group flex items-center justify-center">
        <span className="flex items-center justify-center w-4.5 h-4.5 rounded-full border border-gray-400 text-gray-500 text-[11px] font-bold cursor-help hover:border-black hover:text-black transition-colors">!</span>
        <div className="absolute left-1/2 top-full mt-2 -translate-x-1/2 hidden group-hover:block w-64 p-3 bg-black text-white text-xs font-normal rounded-lg shadow-xl z-50 text-center leading-relaxed">
          Mỗi 10.000 VND tiền hàng trước giảm giá được 1 điểm, lấy phần nguyên. Điểm được cộng khi giao thành công.
          <div className="absolute bottom-full left-1/2 -translate-x-1/2 border-4 border-transparent border-b-black"></div>
        </div>
      </div>
    </div>
  }>

    {notice && <p className="text-sm mb-4" role="status">{notice}</p>}
    {loading ? <div className="h-40 bg-gray-100 animate-pulse rounded-lg mb-8" aria-label="Đang tải điểm thưởng" /> : error ? <p role="alert" className="text-sm mb-6">{error}<button className="underline ml-3" onClick={() => setVersion(value => value + 1)}>Thử lại</button></p> : data && <>
      <div className="border rounded-lg px-5 py-5 mb-7 flex flex-wrap justify-between items-center gap-5"><div><p className="text-xs text-gray-500 mb-1">Số dư hiện tại</p>
        <strong className="text-3xl">{data.balance.toLocaleString("vi-VN")}</strong><span className="text-sm text-gray-500 ml-2">điểm</span></div>
        <div className="text-right"><p className="text-sm font-semibold">Hạng {({ STANDARD: "Thành viên", SILVER: "Bạc", GOLD: "Vàng" })[data.tier] ?? data.tier}</p>
          <p className="text-xs text-gray-500 mt-1">Điểm đổi ưu đãi không làm giảm hạng thành viên.</p></div></div>
      {data.adjustmentPoints > 0 && <p className="text-sm text-gray-500 mb-5" role="status">Bạn đã sử dụng điểm từ sản phẩm đã trả. Còn {data.adjustmentPoints.toLocaleString("vi-VN")} điểm cần điều chỉnh từ điểm tích lũy của các đơn tiếp theo trước khi cộng vào số dư. Bạn không phải trả thêm tiền.</p>}
      <section className="mb-8"><button className="w-full flex justify-between items-center text-lg font-bold mb-3" aria-expanded={voucherOpen} onClick={() => { setNow(Date.now()); setVoucherOpen(value => !value); }}>
        <span>Voucher của tôi <small className="text-xs text-gray-500 font-normal ml-2">{data.vouchers.totalElements}</small></span><span aria-hidden="true">{voucherOpen ? "−" : "+"}</span></button>
        {voucherOpen && <div className="space-y-2">{wallet.loading && <div aria-label="Đang tải voucher" className="h-24 bg-gray-100 animate-pulse rounded" />}{wallet.error && <p role="alert" className="text-sm">{wallet.error}<button className="ml-2 underline" onClick={() => setVersion(value => value + 1)}>Thử lại</button></p>}{voucherData?.totalElements === 0 && <p className="text-sm text-gray-500">Chưa có voucher đã đổi.</p>}{voucherData?.content.map(voucher => {
          const expired = utcDate(voucher.expiresAt).getTime() <= now; const unavailable = voucher.used || expired;
          return <article key={voucher.id} className="border rounded-lg p-3 flex items-center justify-between gap-3"><div className="min-w-0"><strong className="text-sm">{voucher.name}</strong><p className="text-xs text-gray-500 mt-1">{voucher.used ? "Đã dùng" : expired ? "Đã hết hạn" : `Hạn dùng ${displayDate(voucher.expiresAt)}`}</p><code className="block text-xs text-gray-500 break-all mt-1">{voucher.code}</code></div>
            <button disabled={unavailable} className="text-xs font-semibold underline shrink-0 disabled:text-gray-400" onClick={async () => { try { await navigator.clipboard.writeText(voucher.code); setNotice("Đã sao chép mã. Nhập mã này khi đặt hàng."); } catch { setNotice("Không sao chép được. Bạn có thể chọn và sao chép mã bên cạnh."); } }}>Sao chép</button></article>;
        })}
          {voucherData && voucherData.totalPages > 1 && <nav aria-label="Phân trang voucher" className="flex justify-end items-center gap-3 text-xs mt-3"><button disabled={voucherPage === 0} className="border rounded px-3 py-2 disabled:opacity-40" onClick={() => setVoucherPage(value => value - 1)}>Trước</button><span>{voucherPage + 1} / {voucherData.totalPages}</span><button disabled={voucherPage + 1 >= voucherData.totalPages} className="border rounded px-3 py-2 disabled:opacity-40" onClick={() => setVoucherPage(value => value + 1)}>Sau</button></nav>}
        </div>}</section>
      <RewardExchange balance={data.balance} rewards={data.rewards} onRedeemed={() => { setVersion(value => value + 1); setVoucherOpen(true); setVoucherPage(0); setNotice("Đã đổi ưu đãi. Voucher đã được lưu vào tài khoản."); }} />
    </>}
    <PointHistory version={version} />
  </AccountLayout>;
}
