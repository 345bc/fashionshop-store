import CheckoutItems from "./CheckoutItems";
import CartSkeleton, { CartSummarySkeleton } from "@/components/skeleton-ui/CartSkeleton";
import { money, type CartItem, type CheckoutPrice } from "@/cart/types";

export default function CheckoutSummary({ items, subtotal, shippingFee, total, loading = false, discount = 0, pricing, pricesLoading = false, priceError = "", onRetryPrice, voucherCode, onVoucherChange, onApplyVoucher, voucherBusy = false, voucherDisabled = false, voucherError = "", voucherHint = "" }: {
  items: CartItem[]; subtotal: number; shippingFee: number; total: number; loading?: boolean; discount?: number;
  pricing?: CheckoutPrice; pricesLoading?: boolean; priceError?: string; onRetryPrice?: () => void;
  voucherCode?: string; onVoucherChange?: (value: string) => void; onApplyVoucher?: () => void; voucherBusy?: boolean; voucherDisabled?: boolean; voucherError?: string; voucherHint?: string;
}) {
  return <aside className="sticky top-24 lg:pl-10">
    <h2 className="text-[22px] font-normal text-gray-900 mb-6">Tổng quan đơn hàng</h2>

    {loading ? <CartSkeleton /> : <CheckoutItems items={items} />}

    {loading ? <CartSummarySkeleton /> : <>
      {onVoucherChange && <div className="mt-6 mb-6">
        <h3 className="text-sm font-semibold mb-3">Mã ưu đãi</h3>
        <div className="flex gap-2">
          <input
            type="text"
            placeholder="Mã giảm giá"
            aria-label="Mã ưu đãi" aria-describedby={voucherHint ? "checkout-voucher-hint" : undefined} maxLength={50} value={voucherCode ?? ""} disabled={voucherDisabled || voucherBusy} onChange={event => onVoucherChange(event.target.value)}
            className="flex-1 border border-gray-200 rounded-lg px-4 py-2.5 text-[14px] font-normal text-gray-900 placeholder-gray-400 focus:outline-none focus:border-gray-400 transition-colors disabled:bg-gray-50 disabled:text-gray-400 disabled:cursor-not-allowed"
          />
          <button type="button" disabled={voucherBusy || voucherDisabled || !voucherCode?.trim() || !!voucherError} onClick={onApplyVoucher} className="bg-black text-white px-5 py-2.5 rounded-lg text-[14px] font-medium hover:bg-gray-800 transition-colors disabled:bg-gray-400 disabled:cursor-not-allowed disabled:hover:bg-gray-400">
            {voucherBusy ? "Đang kiểm tra..." : "Áp dụng"}
          </button>
        </div>
        {voucherHint && <p id="checkout-voucher-hint" className="text-xs text-gray-500 mt-2">{voucherHint}</p>}
        {voucherError && <p role="alert" className="text-sm text-red-600 mt-2">{voucherError}</p>}
      </div>}

      {priceError && <p role="alert" className="text-sm text-red-700 my-4">{priceError}<button type="button" className="underline ml-2" onClick={onRetryPrice}>Thử lại</button></p>}
      {pricesLoading || priceError ? <CartSummarySkeleton /> : <><div className="flex flex-col gap-4">
        <div className="flex justify-between items-start text-[14px]">
          <span className="text-gray-600 font-normal">Tổng phụ</span>
          <span className="font-medium text-gray-800">{money(subtotal)}</span>
        </div>

        <div className="flex justify-between items-start text-[14px]">
          <div className="flex flex-col gap-1 pr-4">
            <span className="text-gray-600 font-normal">Phí vận chuyển cố định</span>
            <span className="text-gray-600 font-normal">{money(pricing?.shippingBaseFee ?? shippingFee)}</span>
            {pricing && pricing.shippingPromotionAmount > 0 && <span className="text-gray-600 font-normal text-[13px] mt-1">Giảm {money(pricing.shippingPromotionAmount)} phí vận chuyển cho đơn từ {money(pricing.shippingDiscountThreshold)} (áp dụng tự động)</span>}
            {pricing && pricing.shippingDiscountAmount > 0 && <span className="text-xs text-gray-500">Đã giảm {money(pricing.shippingDiscountAmount)}</span>}
          </div>
          <span className="font-medium text-gray-800 shrink-0 mt-auto">{money(shippingFee)}</span>
        </div>

        <div className="flex justify-between items-start text-[14px]">
          <span className="text-gray-600 font-normal">Giảm giá thành viên</span>
          <div className="flex flex-col items-end gap-1">
            <span className="font-medium text-gray-800">{money(pricing?.membershipDiscountAmount ?? 0)}</span>
            <span className="text-gray-600 font-normal">{pricing?.membershipDiscountPercent ?? 0}%</span>
          </div>
        </div>

        <div className="flex justify-between items-start text-[14px]">
          <span className="text-gray-600 font-normal">Giảm giá coupon</span>
          <span className="font-medium text-gray-800">{money(pricing?.couponDiscountAmount ?? discount)}</span>
        </div>
      </div>

      <div className="flex justify-between items-end pt-6 mt-4">
        <span className="text-[20px] font-black text-gray-900 tracking-wide">Tổng</span>
        <strong className="text-[22px] font-black text-gray-900 tracking-tight">{money(total)}</strong>
      </div></>}
    </>}
  </aside>;
}
