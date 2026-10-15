import type { CartLine, PendingCheckout } from "@/cart/types";

async function updateFlow(body: object) {
  const response = await fetch("/api/checkout-flow", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });
  if (!response.ok) throw new Error((await response.json()).message || "Không xác minh được phiên đặt hàng");
}
export function startCheckoutFlow(items: CartLine[]) { return updateFlow({ phase: "checkout", items }); }
export function completeCheckoutFlow(order: Pick<PendingCheckout, "code" | "checkoutToken">) { return updateFlow({ phase: "paid", ...order }); }
export async function clearCheckoutFlow() {
  const response = await fetch("/api/checkout-flow", { method: "DELETE" });
  if (!response.ok) throw new Error("Không kết thúc được phiên đặt hàng");
}
