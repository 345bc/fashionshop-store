"use client";

import { useEffect, useRef, useState, type FormEvent } from "react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import { lookupOrder } from "@/service/orderTrackingService";
import type { OrderTracking } from "@/type/orderTracking";
import OrderTrackingResult from "./OrderTrackingResult";
import OrderTrackingSkeleton from "@/components/skeleton-ui/OrderTrackingSkeleton";

export default function OrderTrackingPage() {
  const [code, setCode] = useState("");
  const [phone, setPhone] = useState("");
  const [order, setOrder] = useState<OrderTracking | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const request = useRef<AbortController | null>(null);
  useEffect(() => () => request.current?.abort(), []);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    request.current?.abort();
    const controller = new AbortController();
    request.current = controller;
    setLoading(true); setError(""); setOrder(null);
    try {
      const result = await lookupOrder(code, phone, controller.signal);
      if (!controller.signal.aborted) setOrder(result);
    } catch (cause) {
      if (!controller.signal.aborted) setError(cause instanceof Error ? cause.message : "Không tra cứu được đơn hàng. Vui lòng thử lại.");
    } finally {
      if (!controller.signal.aborted) setLoading(false);
    }
  }

  return (
    <>
      <Header />
      <main className="container mx-auto min-h-[65vh] px-4 py-14 text-black sm:px-6 sm:py-20 lg:px-8">
        <p className="text-xs font-medium uppercase tracking-widest text-black/45">Chăm sóc khách hàng</p>
        <h1 className="mt-3 text-3xl font-semibold tracking-tight sm:text-4xl">Tra cứu đơn hàng</h1>
        <p className="mt-4 max-w-xl text-sm leading-6 text-black/55">Kiểm tra đơn hàng bằng mã đơn và số điện thoại nhận hàng. Bạn không cần đăng nhập.</p>
        <div className="mt-10 grid gap-12 lg:grid-cols-[340px_1fr] lg:gap-20">
          <form onSubmit={submit} className="space-y-6">
            <div>
              <label htmlFor="tracking-code" className="mb-2 block text-sm font-semibold">Mã đơn hàng</label>
              <input id="tracking-code" value={code} onChange={event => { setCode(event.target.value); setOrder(null); setError(""); }} required maxLength={32} disabled={loading} autoComplete="off" placeholder="ORD-…" className="w-full rounded-lg border border-black/20 bg-white px-4 py-3 text-sm outline-none focus:border-black disabled:opacity-50" />
              <p className="mt-2 text-xs leading-5 text-black/45">Mã được hiển thị sau khi bạn đặt hàng.</p>
            </div>
            <div>
              <label htmlFor="tracking-phone" className="mb-2 block text-sm font-semibold">Số điện thoại nhận hàng</label>
              <input id="tracking-phone" type="tel" inputMode="tel" value={phone} onChange={event => { setPhone(event.target.value); setOrder(null); setError(""); }} required pattern="0[0-9]{9}" maxLength={10} disabled={loading} autoComplete="tel" placeholder="Nhập số điện thoại 10 chữ số" className="w-full rounded-lg border border-black/20 bg-white px-4 py-3 text-sm outline-none focus:border-black disabled:opacity-50" />
            </div>
            <button type="submit" disabled={loading} className="w-full rounded-lg bg-black px-5 py-3.5 text-sm font-semibold text-white transition-colors hover:bg-black/80 disabled:opacity-50">{loading ? "Đang tra cứu…" : "Tra cứu đơn hàng"}</button>
            {error && <p role="alert" className="text-sm leading-6 text-red-700">{error}</p>}
          </form>
          <div aria-live="polite" aria-busy={loading}>
            {loading ? <OrderTrackingSkeleton /> : order ? <OrderTrackingResult order={order} /> : (
              <div className="border-t border-black/10 pt-6">
                <h2 className="text-base font-semibold">Theo dõi quá trình xử lý đơn</h2>
                <p className="mt-3 max-w-md text-sm leading-7 text-black/50">Thông tin thanh toán và giao hàng sẽ xuất hiện tại đây sau khi tra cứu. Nhập đúng số điện thoại đã điền ở phần người nhận.</p>
              </div>
            )}
          </div>
        </div>
      </main>
      <Footer />
    </>
  );
}
