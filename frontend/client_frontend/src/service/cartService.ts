import { apiRequest } from "@/api/apiClient";
import type { ApiResponse } from "@/type/api";
import type { CartLine, CartResponse, PendingCheckout, CheckoutPrice } from "@/cart/types";

export async function getCart(signal?: AbortSignal): Promise<CartResponse> {
  const response: ApiResponse<CartResponse> = await apiRequest("/cart", { signal });
  return response.data;
}
export async function quoteCart(items: CartLine[], signal?: AbortSignal): Promise<CartResponse> {
  const response: ApiResponse<CartResponse> = await apiRequest("/cart/quote", { method: "POST", body: { items }, signal });
  return response.data;
}
export async function mergeCart(mergeKey: string, items: CartLine[], signal?: AbortSignal): Promise<CartResponse> {
  const response: ApiResponse<CartResponse> = await apiRequest("/cart/merge", { method: "POST", body: { mergeKey, items }, signal });
  return response.data;
}
export async function mutateCart(path: string, method: string, body?: object): Promise<CartResponse> {
  const response: ApiResponse<CartResponse> = await apiRequest(`/cart${path}`, { method, body });
  return response.data;
}
export async function createCheckout(body: {
  recipientName: string; recipientPhone: string; address: string; note: string;
  shippingMethod: string; items: CartLine[];
  checkoutKey: string; voucherCode?: string;
}): Promise<PendingCheckout> {
  const response: ApiResponse<PendingCheckout> = await apiRequest("/checkout/orders", { method: "POST", body });
  return response.data;
}
export async function quoteCheckout(items: CartLine[], shippingMethod: string, voucherCode: string, signal?: AbortSignal) {
  const response: ApiResponse<CheckoutPrice> = await apiRequest("/checkout/orders/quote", { method: "POST", body: { voucherCode, shippingMethod, items }, signal });
  return response.data;
}
export async function quoteVoucher(items: CartLine[], code: string, signal?: AbortSignal) {
  const response: ApiResponse<CheckoutPrice> = await apiRequest("/checkout/orders/voucher", { method: "POST", body: { code, items }, signal });
  return response.data;
}
export async function checkoutStatus(order: Pick<PendingCheckout, "code" | "checkoutToken">, cancel = false): Promise<PendingCheckout> {
  const response: ApiResponse<PendingCheckout> = await apiRequest(`/checkout/orders/${encodeURIComponent(order.code)}${cancel ? "/cancel" : ""}`, {
    method: cancel ? "POST" : "GET", headers: { "X-Checkout-Token": order.checkoutToken },
  });
  return { ...response.data, checkoutToken: order.checkoutToken };
}
export async function checkoutPayment(order: Pick<PendingCheckout, "code" | "checkoutToken">, signal?: AbortSignal): Promise<{ checkoutUrl: string }> {
  const response: ApiResponse<{ checkoutUrl: string }> = await apiRequest(`/checkout/orders/${encodeURIComponent(order.code)}/payment`, {
    method: "POST", headers: { "X-Checkout-Token": order.checkoutToken }, signal,
  });
  return response.data;
}

export async function verifyCheckoutReturn(order: Pick<PendingCheckout, "code" | "checkoutToken">, params: URLSearchParams): Promise<void> {
  const response: ApiResponse<{ RspCode: string; Message: string }> = await apiRequest(
    `/checkout/orders/${encodeURIComponent(order.code)}/payment/verify?${params}`, {
      method: "POST", headers: { "X-Checkout-Token": order.checkoutToken },
    });
  if (!["00", "02"].includes(response.data.RspCode)) {
    throw new Error("Không xác minh được kết quả thanh toán VNPay. Vui lòng kiểm tra lại.");
  }
}
