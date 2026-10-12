"use client";

import { useEffect, useState } from "react";
import type { PendingCheckout } from "@/cart/types";
import { checkoutPayment } from "@/service/cartService";

export default function CheckoutPayment({ order }: { order: PendingCheckout }) {
  const [attempt, setAttempt] = useState(0);
  const [result, setResult] = useState<{ code: string; checkoutUrl?: string; error?: string; attempt: number } | null>(null);
  const code = order.code, token = order.checkoutToken;
  const current = result?.code === code && result.attempt === attempt ? result : null;

  useEffect(() => {
    const controller = new AbortController();
    checkoutPayment({ code, checkoutToken: token }, controller.signal)
      .then(data => {
        if (!controller.signal.aborted) setResult({ code, attempt, checkoutUrl: data.checkoutUrl });
      })
      .catch(cause => {
        if (!controller.signal.aborted) setResult({ code, attempt, error: cause instanceof Error ? cause.message : "Chưa mở được thanh toán" });
      });
    return () => controller.abort();
  }, [code, token, attempt]);

  if (!current) return <div className="h-20 animate-pulse motion-reduce:animate-none bg-gray-200 rounded" aria-busy="true" aria-label="Đang chuẩn bị thanh toán" />;
  if (current.error) return <div className="text-sm">
    <p role="alert" className="text-gray-600 mb-3">{current.error}</p>
    <button type="button" className="underline font-semibold" onClick={() => setAttempt(value => value + 1)}>Thử lại thanh toán</button>
  </div>;
  return <div className="text-sm">
    <a href={current.checkoutUrl}
      className="block text-center bg-black text-white px-5 py-3 rounded font-semibold">Thanh toán qua VNPay</a>
    <p className="text-gray-500 mt-3 leading-relaxed">Bạn sẽ được chuyển sang VNPay và quay lại trang này sau thanh toán. Đơn tự xác nhận khi VNPay thông báo giao dịch thành công. Không thanh toán sau khi hết thời gian.</p>
  </div>;
}
