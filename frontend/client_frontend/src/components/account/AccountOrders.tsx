"use client";
import GoogleSymbol from "@/components/ui/GoogleSymbol";

import { useRef, useState } from "react";
import Link from "next/link";
import AccountLayout from "./AccountLayout";
import AccountDialog from "./AccountDialog";
import OrderStatusBadge from "./OrderStatusBadge";
import OrderStatusTimeline from "@/components/OrderStatusTimeline";
import Notification from "@/utils/Notification";
import CartSkeleton from "@/components/skeleton-ui/CartSkeleton";
import { useCart } from "@/cart/CartContext";
import useAccountQuery from "./useAccountQuery";
import { money } from "@/cart/types";
import { orderStatuses, orderStatusLabel } from "@/utils/orderStatus";
import { apiError, cancelOrder, displayDate, paymentLabel, reorder, requestReturn, saveReview, utcDate, type CustomerOrder, type PurchasedItem } from "@/service/accountService";
import type { PageResponse } from "@/type/api";

const actionClass = "border border-gray-300 rounded-md px-3 py-2 text-xs font-semibold disabled:opacity-40";

const canReturn = (order: CustomerOrder) => {
  if (order.status !== "DELIVERED") return false;
  if (!order.items.some(item => item.returnedQuantity < item.quantity)) return false;
  
  const deliveryHistories = order.history.filter(h => h.status === "DELIVERED");
  if (deliveryHistories.length === 0) return true; // Fallback
  
  const latestDelivery = deliveryHistories.reduce((latest, current) => {
    return new Date(utcDate(current.createdAt)).getTime() > new Date(utcDate(latest.createdAt)).getTime() ? current : latest;
  }, deliveryHistories[0]);
  
  const deliveryDate = utcDate(latestDelivery.createdAt).getTime();
  const now = new Date().getTime();
  const daysDiff = (now - deliveryDate) / (1000 * 60 * 60 * 24);
  
  return daysDiff <= 14;
};

export default function AccountOrders() {
  const cart = useCart();
  const [page, setPage] = useState(0); const [status, setStatus] = useState("ALL");
  const [notice, setNotice] = useState("");
  const [version, refresh] = useState(0); const [busy, setBusy] = useState(false);
  const [cancel, setCancel] = useState<CustomerOrder | null>(null);
  const [detail, setDetail] = useState<CustomerOrder | null>(null);
  const [review, setReview] = useState<{ order: CustomerOrder; item: PurchasedItem } | null>(null);
  const [returnOrder, setReturnOrder] = useState<CustomerOrder | null>(null);
  const keys = useRef(new Map<number, string>());
  const { data: response, loading, error } = useAccountQuery<PageResponse<CustomerOrder>>(`/me/orders?page=${page}&size=10&status=${status}`, version);
  async function buyAgain(order: CustomerOrder) {
    setBusy(true); setNotice("");
    try {
      const key = keys.current.get(order.id) ?? crypto.randomUUID(); keys.current.set(order.id, key);
      await reorder(order.id, key); keys.current.delete(order.id); await cart.refresh(); cart.openCart();
    } catch (error) { setNotice(apiError(error)); } finally { setBusy(false); }
  }
  const changed = () => { setPage(0); refresh(value => value + 1); };
  return <AccountLayout active="orders" title="Đơn hàng của tôi">
    <div className="flex justify-end mb-3"><button className="text-xs text-gray-500 underline disabled:opacity-40" disabled={loading} onClick={changed}>Làm mới</button></div>
    <div className="flex gap-2 overflow-x-auto pb-4 mb-3" aria-label="Lọc đơn theo trạng thái">
      {[{ value: "ALL", label: "Tất cả" }, ...orderStatuses].map(tab => <button key={tab.value} type="button" aria-pressed={status === tab.value}
        className={`${actionClass} whitespace-nowrap ${status === tab.value ? "bg-black text-white border-black" : "text-gray-600"}`}
        onClick={() => { setStatus(tab.value); setPage(0); }}>{tab.label}</button>)}</div>
    {notice && <p role="status" className="text-sm mb-4">{notice}</p>}
    {loading ? <CartSkeleton /> : error ? <div role="alert" className="border rounded-lg p-5 text-sm">{error}<button className="underline ml-3" onClick={changed}>Thử lại</button></div>
      : !response?.content.length ? <p className="py-12 text-center text-sm text-gray-500">Chưa có đơn hàng trong mục này.</p>
        : <div className="space-y-5">{response.content.map(order => <article key={order.id} className="border border-gray-200 rounded-lg overflow-hidden">
          <header className="flex flex-wrap items-center justify-between gap-3 bg-gray-50 px-4 py-3 text-xs"><div><strong>{order.code}</strong><span className="ml-3 text-gray-500">{displayDate(order.createdAt)}</span></div>
            <div className="flex flex-wrap items-center gap-3"><OrderStatusBadge status={order.status} /><span className="text-gray-500">{paymentLabel(order.paymentStatus)}</span></div></header>
          <div className="px-4 divide-y divide-gray-100">{order.items.map(item => <div key={item.id} className="flex gap-4 py-4">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            {item.imageUrl && <img src={item.imageUrl} alt={item.name} className="w-16 h-20 object-cover rounded shrink-0" />}
            <div className="flex-1 min-w-0"><Link href={`/product/${item.slug || item.variantId}`} className="text-sm font-semibold">{item.name}</Link>
              <p className="mt-1 text-xs text-gray-500">{item.colorName} / {item.sizeName} · Số lượng {item.quantity}</p>
              {item.returnedQuantity > 0 && <p className="text-xs text-gray-500 mt-1">Đã yêu cầu trả: {item.returnedQuantity}</p>}
              {item.review && <p className="text-xs mt-2 text-gray-600"><span className="font-semibold text-gray-900">{item.review.rating}/5</span> · {item.review.hidden ? "Đánh giá đang bị ẩn" : item.review.comment || "Đã đánh giá"}</p>}
              {item.canReview && <button type="button" className={`inline-flex items-center gap-1.5 text-xs rounded-md px-3 py-2 mt-3 font-semibold disabled:opacity-40 ${item.review ? "border border-gray-300 text-gray-700 hover:bg-gray-50" : "bg-zinc-900 text-white hover:bg-black"}`} disabled={busy} onClick={() => setReview({ order, item })}><GoogleSymbol name={item.review ? "edit" : "rate_review"} size={17} />{item.review ? "Sửa đánh giá" : "Viết đánh giá"}</button>}
            </div><strong className="text-sm shrink-0">{money(item.unitPrice * item.quantity)}</strong>
          </div>)}</div>
          <footer className="border-t px-4 py-3 flex flex-wrap items-center justify-between gap-3"><p className="text-sm text-gray-500">Tổng <strong className="text-base text-black ml-2">{money(order.totalAmount)}</strong></p>
            <div className="flex flex-wrap gap-2"><button className={actionClass} onClick={() => setDetail(order)}>Chi tiết</button>
              {order.status === "PENDING" && order.paymentStatus === "PENDING" && <button className={actionClass} onClick={() => setCancel(order)}>Hủy đơn</button>}
              {canReturn(order) && <button className={actionClass} onClick={() => setReturnOrder(order)}>Yêu cầu trả hàng</button>}
              <button className={actionClass} disabled={busy} onClick={() => void buyAgain(order)}>Mua lại</button></div></footer>
        </article>)}</div>}
    {response && response.totalPages > 1 && <nav aria-label="Phân trang đơn hàng" className="flex justify-end items-center gap-4 mt-5 text-sm">
      <button className={actionClass} disabled={loading || page === 0} onClick={() => setPage(value => value - 1)}>Trước</button>
      <span>{page + 1} / {response.totalPages}</span><button className={actionClass} disabled={loading || page + 1 >= response.totalPages} onClick={() => setPage(value => value + 1)}>Sau</button></nav>}
    <Notification open={!!cancel} title="Hủy đơn hàng" message={`Hủy đơn ${cancel?.code ?? ""}?`} onClose={() => setCancel(null)} onConfirm={async () => { if (cancel) { await cancelOrder(cancel.id); changed(); } }} />
    {detail && <AccountDialog title={detail.code} onClose={() => setDetail(null)}><div className="mb-5"><OrderStatusBadge status={detail.status} /></div><OrderStatusTimeline status={detail.status} />
      <div className="my-6 text-sm space-y-2"><p className="font-semibold">{paymentLabel(detail.paymentStatus)}</p><p>{detail.recipientName} · {detail.recipientPhone}</p><p className="text-gray-500">{detail.address}</p>
        <p>Tiền hàng: {money(detail.subtotal)} · Phí vận chuyển: {money(detail.shippingFee)}</p><p>Giảm giá: {money(detail.discountAmount)}</p><p className="font-bold">Tổng: {money(detail.totalAmount)}</p></div>
      <h3 className="text-sm font-bold mb-3">Lịch sử xử lý</h3><ul className="space-y-3 text-xs">{detail.history.map((entry, index) => <li key={index}><strong>{orderStatusLabel(entry.status)}</strong><span className="text-gray-500 ml-3">{displayDate(entry.createdAt)}</span></li>)}</ul>
    </AccountDialog>}
    {review && <ReviewForm order={review.order} item={review.item} onClose={() => setReview(null)} onSaved={() => { setReview(null); changed(); }} />}
    {returnOrder && <ReturnForm order={returnOrder} onClose={() => setReturnOrder(null)} onSaved={() => { setReturnOrder(null); setNotice("Đã gửi yêu cầu trả hàng. Cửa hàng sẽ kiểm tra và xử lý."); changed(); }} />}
  </AccountLayout>;
}

function ReviewForm({ order, item, onClose, onSaved }: { order: CustomerOrder; item: PurchasedItem; onClose: () => void; onSaved: () => void }) {
  const [rating, setRating] = useState(item.review?.rating ?? 5); const [comment, setComment] = useState(item.review?.comment ?? "");
  const [busy, setBusy] = useState(false); const [error, setError] = useState("");
  return <AccountDialog title="Đánh giá sản phẩm" onClose={onClose} busy={busy}><p className="text-sm font-semibold mb-4">{item.name}</p>
    <form onSubmit={async event => { event.preventDefault(); if (busy) return; setBusy(true); setError(""); try { await saveReview(order.id, item.id, rating, comment); onSaved(); } catch (error) { setError(apiError(error)); } finally { setBusy(false); } }}>
      <fieldset disabled={busy}><legend className="text-sm mb-2">Mức độ hài lòng</legend><div className="flex gap-2 mb-5">{[1, 2, 3, 4, 5].map(value => <button key={value} type="button" aria-label={`${value} sao`} aria-pressed={rating === value} className={`text-3xl ${value <= rating ? "text-amber-500" : "text-gray-300"}`} onClick={() => setRating(value)}><GoogleSymbol name="star" size={28} filled={value <= rating} /></button>)}</div>
        <label className="text-sm block">Nội dung<textarea maxLength={1000} value={comment} onChange={event => setComment(event.target.value)} className="w-full border rounded p-3 mt-2 text-sm" rows={4} /></label></fieldset>
      {error && <p role="alert" className="text-sm text-red-600 my-3">{error}</p>}<button disabled={busy} className="bg-black text-white rounded px-4 py-2 text-sm mt-3">{busy ? "Đang lưu..." : "Lưu đánh giá"}</button>
    </form></AccountDialog>;
}
function ReturnForm({ order, onClose, onSaved }: { order: CustomerOrder; onClose: () => void; onSaved: () => void }) {
  const [quantities, setQuantities] = useState<Record<number, number>>({}); const [reason, setReason] = useState("");
  const [busy, setBusy] = useState(false); const [error, setError] = useState("");
  return <AccountDialog title="Yêu cầu trả hàng" onClose={onClose} busy={busy}><form onSubmit={async event => { event.preventDefault(); if (busy) return; setBusy(true); setError(""); try {
    const items = Object.entries(quantities).filter(([, qty]) => qty > 0).map(([id, quantity]) => ({ orderItemId: Number(id), quantity }));
    if (!items.length) throw new Error("Chọn ít nhất một sản phẩm cần trả.");
    await requestReturn(order.id, reason.trim(), items); onSaved();
  } catch (error) { setError(apiError(error)); } finally { setBusy(false); } }}><fieldset disabled={busy} className="space-y-4">
    {order.items.filter(item => item.quantity > item.returnedQuantity).map(item => <label key={item.id} className="flex justify-between items-center gap-4 text-sm"><span>{item.name}<small className="block text-gray-500">{item.colorName} / {item.sizeName}</small></span>
      <input aria-label={`Số lượng trả ${item.name}`} type="number" min={0} max={item.quantity - item.returnedQuantity} value={quantities[item.id] ?? 0} className="border rounded p-2 w-20" onChange={event => setQuantities({ ...quantities, [item.id]: Number(event.target.value) })} /></label>)}
    <label className="block text-sm">Lý do trả<textarea required maxLength={500} rows={3} className="border rounded p-3 mt-2 w-full" value={reason} onChange={event => setReason(event.target.value)} /></label>
    <p className="text-xs text-gray-500">Điểm tích lũy sẽ được điều chỉnh khi cửa hàng nhận hàng trả.</p></fieldset>
    {error && <p role="alert" className="text-sm text-red-600 mt-3">{error}</p>}<button disabled={busy} className="bg-black text-white rounded px-4 py-2 mt-4 text-sm">{busy ? "Đang gửi..." : "Gửi yêu cầu"}</button>
  </form></AccountDialog>;
}
