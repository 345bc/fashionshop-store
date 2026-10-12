"use client";
import GoogleSymbol from "@/components/ui/GoogleSymbol";


import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { getProductDetail } from "@/service/productService";
import { useCart } from "./CartContext";
import { money, type CartItem } from "./types";
import Notification from "@/utils/Notification";
import CartSkeleton from "@/components/skeleton-ui/CartSkeleton";

type VariantOption = { id: number; label: string; available: number };
function CartRow({ item, selectable }: { item: CartItem; selectable: boolean }) {
  const cart = useCart();
  const [error, setError] = useState("");
  const [editing, setEditing] = useState(false);
  const [options, setOptions] = useState<VariantOption[]>([]);
  const [nextId, setNextId] = useState(item.variantId);
  const [optionsLoading, setOptionsLoading] = useState(false);
  async function run(action: () => Promise<void>) {
    setError("");
    try { await action(); } catch (cause) { setError(cause instanceof Error ? cause.message : "Không cập nhật được giỏ hàng"); }
  }
  async function editVariant() {
    if (!item.slug) return;
    setEditing(true); setOptionsLoading(true); setError("");
    try {
      const { data } = await getProductDetail(item.slug);
      const colors = data.colors as { id: number; name: string }[];
      const sizes = data.sizes as { id: number; name: string }[];
      setOptions((data.variants as { id: number; colorId: number; sizeId: number; stockQuantity: number }[]).map(v => ({
        id: v.id, available: v.stockQuantity,
        label: `${colors.find(c => c.id === v.colorId)?.name ?? ""} / ${sizes.find(s => s.id === v.sizeId)?.name ?? ""}`,
      })));
    } catch (cause) { setError(cause instanceof Error ? cause.message : "Không tải được biến thể"); }
    finally { setOptionsLoading(false); }
  }
  return <article className="cart-item">
    {selectable && <input className="cart-item-check" type="checkbox" checked={cart.selectedIds.includes(item.variantId)} onChange={() => cart.toggleSelected(item.variantId)} aria-label={`Chọn ${item.name}`} disabled={cart.busy} />}
    <div className="cart-item-image">
      {item.imageUrl ? <Image unoptimized src={item.imageUrl} alt={item.name} fill sizes="96px" className="object-contain" /> : <span>Chưa có ảnh</span>}
    </div>
    <div className="cart-item-info">
      {item.slug ? <Link href={`/product/${encodeURIComponent(item.slug)}`} onClick={cart.closeCart} className="cart-item-title">{item.name}</Link> : <strong>{item.name}</strong>}
      <div className="cart-item-tags"><span>{item.colorName}</span><span>Size <strong>{item.sizeName}</strong></span></div>
      <span className="cart-unit-price">{money(item.unitPrice)} <span>/ sản phẩm</span></span>
      <div className="cart-item-actions">
        <div className="cart-quantity">
          <button disabled={cart.busy || item.quantity <= 1} aria-label={`Giảm số lượng ${item.name}`} onClick={() => void run(() => cart.update(item.variantId, item.quantity - 1))}><GoogleSymbol name="remove" size={16} /></button>
          <span aria-live="polite">{item.quantity}</span>
          <button disabled={cart.busy || item.quantity >= Math.min(999, item.availableQuantity)} aria-label={`Tăng số lượng ${item.name}`} onClick={() => void run(() => cart.update(item.variantId, item.quantity + 1))}><GoogleSymbol name="add" size={16} /></button>
        </div>
        {item.slug && <button type="button" className="cart-edit-button" disabled={cart.busy || optionsLoading} onClick={() => void editVariant()}>Đổi màu / size</button>}
        <button type="button" className="cart-remove-button" disabled={cart.busy} onClick={() => void run(() => cart.remove(item.variantId))}>Xóa</button>
      </div>
      {editing && <div className="cart-variant-editor">
        {optionsLoading ? <span>Đang tải biến thể...</span> : <>
          <select aria-label="Màu và kích thước" value={nextId} onChange={e => setNextId(Number(e.target.value))} disabled={cart.busy}>
            {options.map(v => <option key={v.id} value={v.id} disabled={v.available < item.quantity}>{v.label}{v.available < item.quantity ? " — Không đủ hàng" : ""}</option>)}
          </select>
          <button type="button" className="cart-save-button" disabled={cart.busy || nextId === item.variantId || !options.some(v => v.id === nextId && v.available >= item.quantity)} onClick={() => void run(async () => { await cart.replace(item.variantId, nextId, item.quantity); setEditing(false); })}>Lưu</button>
          <button type="button" className="cart-editor-cancel" onClick={() => setEditing(false)}>Đóng</button>
        </>}
      </div>}
      {!item.purchasable && <p className="cart-error">{item.unavailableReason}</p>}
      {item.quantity > item.availableQuantity && item.availableQuantity > 0 && <button disabled={cart.busy} className="cart-text-button" onClick={() => void run(() => cart.update(item.variantId, item.availableQuantity))}>Giảm số lượng về {item.availableQuantity}</button>}
      {error && <p role="alert" className="cart-error">{error}</p>}
    </div>
    <div className="cart-line-total"><span>Thành tiền</span><strong>{money(item.lineTotal)}</strong></div>
  </article>;
}
export default function CartItems({ selectable = false }: { selectable?: boolean }) {
  const cart = useCart();
  const [confirmDiscard, setConfirmDiscard] = useState(false);
  if (cart.loading || cart.fetchFailed) return <CartSkeleton />;
  if (cart.error) return <div className="cart-error" role="alert"><p>{cart.error}</p><button className="cart-text-button" onClick={() => void cart.refresh()}>Thử lại</button>{cart.canDiscardGuest && <button type="button" className="cart-text-button block mt-4" onClick={() => setConfirmDiscard(true)}>Xóa giỏ trên máy</button>}{confirmDiscard && <Notification open title="Xóa giỏ trên máy" message="Bạn muốn xóa các sản phẩm trong giỏ trên máy? Giỏ đã lưu trong tài khoản được giữ nguyên." confirmText="Xóa giỏ" onConfirm={cart.discardGuest} onClose={() => setConfirmDiscard(false)} />}</div>;
  if (!cart.items.length) return <div className="cart-empty"><span className="material-symbols-outlined">shopping_bag</span><h2>Giỏ hàng đang trống</h2><p className="cart-muted">Chọn sản phẩm và màu, size bạn yêu thích.</p><Link href="/products" onClick={cart.closeCart} className="cart-primary">Khám phá sản phẩm</Link></div>;
  return <div aria-busy={cart.busy}>{cart.items.map(item => <CartRow key={item.variantId} item={item} selectable={selectable} />)}</div>;
}
