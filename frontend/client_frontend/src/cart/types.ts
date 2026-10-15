export type CartLine = { variantId: number; quantity: number };
export type CartItem = CartLine & {
  productId: number | null; name: string; slug: string | null; sku: string | null;
  colorName: string | null; sizeName: string | null; imageUrl: string | null;
  availableQuantity: number; unitPrice: number; lineTotal: number;
  purchasable: boolean; unavailableReason: string | null;
};
export type CartResponse = { items: CartItem[]; totalQuantity: number; subtotal: number };
export type CheckoutPrice = {
  subtotal: number; shippingBaseFee: number; shippingDiscountAmount: number; shippingFee: number;
  membershipDiscountPercent: number; membershipDiscountAmount: number; couponDiscountAmount: number;
  discountAmount: number; totalAmount: number; shippingDiscountThreshold: number; shippingPromotionAmount: number;
};
export type PendingCheckout = {
  id: number; code: string; status: string; paymentStatus: string;
  totalAmount: number; subtotal: number; shippingFee: number; discountAmount: number;
  pricing?: CheckoutPrice;
  paymentExpiresAt: string; checkoutToken: string;
  items: { variantId: number; name: string; sku: string; quantity: number; unitPrice: number; lineTotal: number }[];
};
export const emptyCart: CartResponse = { items: [], totalQuantity: 0, subtotal: 0 };
export const money = (value: number) => `${value.toLocaleString("vi-VN")} VND`;
