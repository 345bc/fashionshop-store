import { apiRequest } from "@/api/apiClient";
import type { ApiResponse, PageResponse } from "@/type/api";

export type PurchasedItem = {
  id: number; variantId: number; name: string; sku: string; slug: string;
  imageUrl: string | null; colorName: string; sizeName: string; quantity: number;
  unitPrice: number; returnedQuantity: number; canReview: boolean;
  review: { id: number; rating: number; comment: string | null; hidden: boolean } | null;
};
export type CustomerOrder = {
  id: number; code: string; status: string; paymentStatus: string; createdAt: string;
  subtotal: number; shippingFee: number; discountAmount: number; totalAmount: number;
  recipientName: string; recipientPhone: string; address: string;
  items: PurchasedItem[]; history: { status: string; note: string; createdAt: string }[];
};
export type RewardOffer = {
  id: number; name: string; code: string; points: number; type: string; value: number;
  cap: number | null; minimum: number; expiresAt: string; used: boolean;
};
export type RewardSummary = { balance: number; adjustmentPoints: number; tier: string; spending: number; rewards: RewardOffer[]; vouchers: PageResponse<RewardOffer> };
export type PointEntry = { id: number; points: number; balanceAfter: number; description: string; createdAt: string };

async function request<T>(path: string, options: object = {}): Promise<T> {
  const response: ApiResponse<T> = await apiRequest(path, options);
  return response.data;
}
export const cancelOrder = (id: number) => request<CustomerOrder>(`/me/orders/${id}/cancel`, { method: "POST" });
export const reorder = (id: number, key: string) => request(`/me/orders/${id}/reorder`, { method: "POST", body: { key } });
export const saveReview = (orderId: number, itemId: number, rating: number, comment: string) =>
  request(`/me/orders/${orderId}/items/${itemId}/review`, { method: "PUT", body: { rating, comment } });
export const requestReturn = (orderId: number, reason: string, items: { orderItemId: number; quantity: number }[]) =>
  request(`/me/orders/${orderId}/returns`, { method: "POST", body: { orderId, reason, items } });
export const redeemReward = (rewardId: number, key: string) => request<RewardOffer>("/me/loyalty/redeem", { method: "POST", body: { rewardId, key } });
export const apiError = (error: unknown) => error instanceof Error ? error.message : "Không tải được dữ liệu. Vui lòng thử lại.";
export const utcDate = (date: string) => new Date(/Z$|[+-]\d{2}:\d{2}$/.test(date) ? date : `${date}Z`);
export const displayDate = (date: string) => utcDate(date).toLocaleString("vi-VN", { timeZone: "Asia/Ho_Chi_Minh", hour: "2-digit", minute: "2-digit", day: "2-digit", month: "2-digit", year: "numeric" });
export const paymentLabel = (status: string) => ({ PENDING: "Chưa thanh toán", PAID: "Đã thanh toán", REFUND_PENDING: "Chờ hoàn tiền", REFUNDED: "Đã hoàn tiền", FAILED: "Thanh toán thất bại" })[status] ?? status;
