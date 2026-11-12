import { orderStatuses, orderStatusLabel } from "@/utils/orderStatus";
import { displayDate } from "@/service/accountService";
import GoogleSymbol from "@/components/ui/GoogleSymbol";

const steps = [
  { value: "PENDING", label: "Đã đặt hàng", icon: "receipt_long" },
  { value: "CONFIRMED", label: "Đã thanh toán", icon: "payments" },
  { value: "SHIPPED", label: "Đã giao cho đơn vị vận chuyển", icon: "local_shipping" },
  { value: "DELIVERED", label: "Đã nhận hàng", icon: "inventory_2" },
];

export default function OrderStatusTimeline({ status, milestones }: {
  status: string;
  milestones?: Record<string, string>;
}) {
  const current = steps.findIndex(step => step.value === status);
  const terminal = current === -1 ? orderStatuses.find(step => step.value === status) : undefined;
  const reached = current === -1 ? steps.map(step => !!milestones?.[step.value]).lastIndexOf(true) : current;

  return (
    <>
      {reached >= 0 && (
        <ol aria-label={`Tiến trình đơn hàng: ${orderStatusLabel(status)}`} className="flex flex-col sm:flex-row">
          {steps.map((step, index) => {
            const date = milestones?.[step.value];
            const completed = index <= reached;
            return (
              <li key={step.value} aria-current={index === current ? "step" : undefined}
                className={`relative flex min-w-0 flex-1 items-start gap-3 pb-5 last:pb-0 sm:flex-col sm:items-center sm:gap-3 sm:px-2 sm:pb-0 sm:text-center
                  after:absolute after:top-6 after:bottom-[-1.5rem] after:left-[23px] after:w-0.5 last:after:hidden sm:after:bottom-auto sm:after:left-1/2 sm:after:h-0.5 sm:after:w-full
                  ${index < reached ? "after:bg-green-600" : "after:bg-gray-200"}`}>
                <span className={`relative z-10 grid size-12 shrink-0 place-items-center rounded-full border-2 bg-white ${completed ? "border-green-600 text-green-700" : "border-gray-200 text-gray-400"}`}>
                  <GoogleSymbol name={step.icon} size={25} />
                </span>
                <div>
                  <p className={`text-sm font-medium ${completed ? "text-gray-900" : "text-gray-500"}`}>{step.label}</p>
                  {completed && date && <p className="mt-1 text-xs text-gray-500">{displayDate(date)}</p>}
                </div>
              </li>
            );
          })}
        </ol>
      )}
      {current === -1 && (
        <div role="status" className={`flex items-center gap-3 border-y border-gray-200 py-4 ${reached >= 0 ? "mt-5" : ""}`}>
          <GoogleSymbol name={terminal?.icon ?? "schedule"} className="text-gray-600" />
          <div>
            <p className="text-sm font-semibold">{orderStatusLabel(status)}</p>
            {milestones?.[status] && <p className="mt-1 text-xs text-gray-500">{displayDate(milestones[status])}</p>}
            {status === "CANCELLED" && <p className="mt-1 text-xs text-gray-600">Đơn hàng đã dừng xử lý.</p>}
            {status === "RETURNED" && <p className="mt-1 text-xs text-gray-600">Xem trạng thái thanh toán để kiểm tra hoàn tiền.</p>}
          </div>
        </div>
      )}
    </>
  );
}
