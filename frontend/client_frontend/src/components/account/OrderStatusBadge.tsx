import GoogleSymbol from "@/components/ui/GoogleSymbol";
import { orderStatuses, orderStatusLabel } from "@/utils/orderStatus";

const colors: Record<string, string> = {
  PENDING: "bg-amber-50 text-amber-800 border-amber-200",
  CONFIRMED: "bg-zinc-900 text-white border-zinc-900",
  SHIPPED: "bg-blue-50 text-blue-800 border-blue-200",
  DELIVERED: "bg-green-50 text-green-800 border-green-200",
  CANCELLED: "bg-red-50 text-red-700 border-red-200",
  RETURNED: "bg-zinc-100 text-zinc-700 border-zinc-200",
};

export default function OrderStatusBadge({ status }: { status: string }) {
  const icon = orderStatuses.find(item => item.value === status)?.icon ?? "schedule";
  return <span className={`inline-flex items-center gap-1.5 border rounded-md px-2.5 py-1.5 text-xs font-bold whitespace-nowrap ${colors[status] ?? colors.RETURNED}`}>
    <GoogleSymbol name={icon} size={17} />{orderStatusLabel(status)}
  </span>;
}
