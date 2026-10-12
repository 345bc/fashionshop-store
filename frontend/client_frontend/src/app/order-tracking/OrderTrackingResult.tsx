import { money } from "@/cart/types";
import type { OrderTracking } from "@/type/orderTracking";
import OrderStatusTimeline from "@/components/OrderStatusTimeline";
import { orderStatusLabel } from "@/utils/orderStatus";
const payments: Record<string, string> = {
  PENDING: "Chưa thanh toán", PAID: "Đã thanh toán", REFUND_PENDING: "Chờ hoàn tiền", REFUNDED: "Đã hoàn tiền",
};

export default function OrderTrackingResult({ order }: { order: OrderTracking }) {
  return (
    <section aria-label="Kết quả tra cứu" className="min-w-0 border-t border-black pt-6">
      <p className="text-xs font-medium uppercase tracking-widest text-black/45">Đơn hàng của bạn</p>
      <h2 className="mt-3 break-all text-lg font-semibold">{order.code}</h2>
      <p className="mt-2 text-sm text-black/50">Đặt ngày {new Date(order.createdAt).toLocaleString("vi-VN", { timeZone: "Asia/Ho_Chi_Minh" })}</p>
      <dl className="my-7 grid grid-cols-2 gap-4 border-y border-black/10 py-5 text-sm">
        <div><dt className="text-black/50">Trạng thái đơn</dt><dd className="mt-2 font-semibold">{orderStatusLabel(order.status)}</dd></div>
        <div><dt className="text-black/50">Thanh toán</dt><dd className="mt-2 font-semibold">{payments[order.paymentStatus] ?? "Đang cập nhật"}</dd></div>
      </dl>
      <div className="mb-8"><OrderStatusTimeline status={order.status} /></div>
      {order.status === "PENDING" && <p className="mb-6 text-sm leading-6 text-black/60">Đơn được giữ hàng trong 5 phút để thanh toán. Nếu hết hạn chưa thanh toán, đơn sẽ tự hủy.</p>}
      {order.paymentStatus === "REFUND_PENDING" && <p className="mb-6 text-sm leading-6 text-black/60">Cửa hàng đang xử lý hoàn tiền cho đơn hàng này.</p>}
      <h3 className="text-sm font-semibold">Sản phẩm</h3>
      <ul className="mt-2 divide-y divide-black/10">
        {order.items.map((item, index) => (
          <li key={`${item.sku}-${index}`} className="flex items-start justify-between gap-5 py-5">
            <div className="min-w-0"><p className="text-sm font-medium">{item.name}</p><p className="mt-1 break-all text-xs leading-5 text-black/50">{item.sku} · Số lượng {item.quantity}</p></div>
            <strong className="shrink-0 text-sm font-semibold">{money(item.lineTotal)}</strong>
          </li>
        ))}
      </ul>
      <div className="mt-2 flex items-baseline justify-between gap-4 border-t border-black/20 pt-6">
        <span className="text-sm text-black/60">Tổng thanh toán</span><strong className="text-2xl font-semibold">{money(order.totalAmount)}</strong>
      </div>
    </section>
  );
}
