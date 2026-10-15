import { orderStatuses, orderStatusLabel } from "@/utils/orderStatus";

export default function OrderStatusTimeline({ status }: { status: string }) {
  const steps = orderStatuses.slice(0, 4);
  const current = steps.findIndex(step => step.value === status);
  if (current === -1) {
    const terminal = orderStatuses.find(step => step.value === status);
    return (
      <div role="status" className="flex items-center gap-3 border-y border-black/10 py-5">
        <span className="material-symbols-outlined text-black/60" aria-hidden="true">{terminal?.icon ?? "schedule"}</span>
        <div><p className="text-sm font-semibold">{orderStatusLabel(status)}</p>
          {status === "CANCELLED" && <p className="mt-1 text-xs text-black/50">Đơn hàng đã dừng xử lý.</p>}
          {status === "RETURNED" && <p className="mt-1 text-xs text-black/50">Hàng trả đã được ghi nhận. Xem trạng thái thanh toán để kiểm tra hoàn tiền.</p>}
        </div>
      </div>
    );
  }
  return (
    <ol aria-label={`Tiến trình đơn hàng: ${orderStatusLabel(status)}`} className="relative flex flex-col gap-5 sm:flex-row sm:gap-0 sm:before:absolute sm:before:left-[12.5%] sm:before:right-[12.5%] sm:before:top-5 sm:before:h-px sm:before:bg-black/10">
      {steps.map((step, index) => {
        const done = index < current;
        const active = index === current;
        return (
          <li key={step.value} aria-current={active ? "step" : undefined} className="relative flex flex-1 items-center gap-3 sm:flex-col sm:gap-2 sm:text-center">
            <span aria-hidden="true" className={`grid size-10 shrink-0 place-items-center rounded-full border-2 ${done || active ? "border-black bg-black text-white" : "border-gray-200 bg-white text-gray-300"}`}>
              <span className="material-symbols-outlined text-[20px]">{done ? "check" : step.icon}</span>
            </span>
            <div><p className={`text-sm font-semibold ${done || active ? "text-black" : "text-black/35"}`}>{step.label}</p>
              <p className="mt-1 text-xs text-black/45">{active ? "Hiện tại" : done ? "Đã qua bước này" : "Chờ cập nhật"}</p>
            </div>
          </li>
        );
      })}
    </ol>
  );
}
