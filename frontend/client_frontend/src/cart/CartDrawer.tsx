"use client";
import GoogleSymbol from "@/components/ui/GoogleSymbol";


import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { startCheckoutFlow } from "@/service/checkoutFlowService";
import CartItems from "./CartItems";
import { useCart } from "./CartContext";
import { money } from "./types";
import Notification from "@/utils/Notification";
import { CartSummarySkeleton } from "@/components/skeleton-ui/CartSkeleton";

export default function CartDrawer() {
  const router = useRouter();
  const cart = useCart();
  const [startingCheckout, setStartingCheckout] = useState(false);
  const [checkoutError, setCheckoutError] = useState("");
  const [confirmClear, setConfirmClear] = useState(false);
  const canCheckout = !cart.loading && !cart.busy && !cart.error && cart.selectedItems.length > 0 && cart.selectedItems.every(item => item.purchasable);
  const panel = useRef<HTMLElement>(null);
  const { drawerOpen, closeCart } = cart;
  const { fetchFailed, refresh } = cart;
  const showSkeleton = cart.loading || fetchFailed;
  async function beginCheckout() {
    if (!canCheckout || startingCheckout) return;
    setStartingCheckout(true); setCheckoutError("");
    try {
      await startCheckoutFlow(cart.selectedItems.map(({ variantId, quantity }) => ({ variantId, quantity })));
      closeCart(); router.push("/checkout");
    } catch (cause) { setCheckoutError(cause instanceof Error ? cause.message : "Không mở được trang đặt hàng"); }
    finally { setStartingCheckout(false); }
  }
  useEffect(() => {
    if (!drawerOpen || !fetchFailed) return;
    let running = false;
    const timer = setInterval(async () => {
      if (running) return;
      running = true;
      try { await refresh(); } finally { running = false; }
    }, 5000);
    return () => clearInterval(timer);
  }, [drawerOpen, fetchFailed, refresh]);
  useEffect(() => {
    if (!drawerOpen) return;
    const previousFocus = document.activeElement as HTMLElement | null;
    const overflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    panel.current?.focus();
    const keydown = (event: KeyboardEvent) => {
      if (event.defaultPrevented || document.querySelector("dialog[open]")) return;
      if (event.key === "Escape") closeCart();
      if (event.key !== "Tab") return;
      const nodes = panel.current?.querySelectorAll<HTMLElement>('a[href], button:not([disabled]), input:not([disabled]), select:not([disabled])');
      if (!nodes?.length) { event.preventDefault(); return; }
      const first = nodes[0], last = nodes[nodes.length - 1];
      if (event.shiftKey && (document.activeElement === first || document.activeElement === panel.current)) { event.preventDefault(); last.focus(); }
      else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
    };
    document.addEventListener("keydown", keydown);
    return () => { document.body.style.overflow = overflow; document.removeEventListener("keydown", keydown); previousFocus?.focus(); };
  }, [drawerOpen, closeCart]);
  if (!drawerOpen) return null;
  return <div className="cart-drawer-backdrop" onClick={closeCart}>
    <aside ref={panel} tabIndex={-1} className="cart-drawer" role="dialog" aria-modal="true" aria-labelledby="cart-drawer-title" onClick={event => event.stopPropagation()}>
      <header className="cart-drawer-header"><div><h2 id="cart-drawer-title">Giỏ hàng</h2><p className="cart-muted">{cart.totalQuantity} sản phẩm</p></div><button type="button" className="cart-close" onClick={closeCart} aria-label="Đóng giỏ hàng"><GoogleSymbol name="close" size={20} /></button></header>
      <div className="cart-drawer-body"><CartItems selectable />
        {!showSkeleton && !!cart.items.length && <button type="button" className="cart-text-button cart-clear" disabled={cart.busy || !!cart.error} onClick={() => setConfirmClear(true)}>Xóa toàn bộ giỏ</button>}
        {confirmClear && <Notification open title="Xóa giỏ hàng" message="Bạn muốn xóa tất cả sản phẩm khỏi giỏ?" confirmText="Xóa tất cả" onConfirm={cart.clear} onClose={() => setConfirmClear(false)} />}
      </div>
      <footer className="cart-drawer-footer">{showSkeleton ? <CartSummarySkeleton /> : <><p className="cart-muted">Đã chọn <strong>{cart.selectedItems.reduce((sum, item) => sum + item.quantity, 0)} sản phẩm</strong></p><div className="cart-total"><span>Tạm tính</span><strong>{money(cart.selectedSubtotal)}</strong></div><p className="cart-muted">Phí giao hàng được tính khi đặt hàng. Giỏ chưa giữ tồn kho.</p>
        {cart.selectedItems.some(item => !item.purchasable) && <p className="cart-error">Giảm số lượng hoặc bỏ chọn sản phẩm không đủ hàng.</p>}
        {checkoutError && <p role="alert" className="cart-error">{checkoutError}</p>}
        <button type="button" className="cart-primary w-full" disabled={!canCheckout || startingCheckout} onClick={() => void beginCheckout()}>{startingCheckout ? "Đang kiểm tra…" : "Tiến hành đặt hàng"}</button>
      </>}</footer>
    </aside>
  </div>;
}
