import { apiRequest } from "@/api/apiClient";
import type { ApiResponse } from "@/type/api";
import type { OrderTracking } from "@/type/orderTracking";

export async function lookupOrder(code: string, phone: string, signal?: AbortSignal): Promise<OrderTracking> {
  const response: ApiResponse<OrderTracking> = await apiRequest("/checkout/orders/lookup", {
    method: "POST", body: { code: code.trim().toUpperCase(), phone: phone.trim() }, signal,
  });
  return response.data;
}
