export const orderStatuses = [
  { value: "PENDING", label: "Chờ thanh toán", icon: "schedule" },
  { value: "CONFIRMED", label: "Đã xác nhận", icon: "check" },
  { value: "SHIPPED", label: "Đang giao hàng", icon: "local_shipping" },
  { value: "DELIVERED", label: "Đã giao hàng", icon: "check_circle" },
  { value: "CANCELLED", label: "Đã hủy", icon: "close" },
  { value: "RETURNED", label: "Đã trả hàng", icon: "assignment_return" },
] as const;

export function orderStatusLabel(status: string) {
  return orderStatuses.find(item => item.value === status)?.label ?? "Đang cập nhật";
}
