"use client";

import { createContext, useCallback, useContext, useEffect, useRef, useState, type ReactNode } from "react";
import { useAuth } from "@/auth/AuthContext";
import { getCart, mergeCart, mutateCart, quoteCart } from "@/service/cartService";
import { clearMergedGuestCart, GUEST_CART_KEY, readGuestCart, writeGuestCart, withCartStorageLock } from "./guestStorage";
import { emptyCart, type CartLine, type CartResponse } from "./types";

type CartContextValue = CartResponse & {
  loading: boolean; busy: boolean; error: string; fetchFailed: boolean; drawerOpen: boolean;
  selectedIds: number[]; selectedItems: CartResponse["items"]; selectedSubtotal: number;
  openCart: () => void; closeCart: () => void; toggleSelected: (id: number) => void;
  refresh: () => Promise<void>; add: (variantId: number, quantity: number) => Promise<void>;
  update: (variantId: number, quantity: number) => Promise<void>; remove: (variantId: number) => Promise<void>;
  replace: (variantId: number, nextVariantId: number, quantity: number) => Promise<void>;
  clear: () => Promise<void>; consumeGuest: (items: CartLine[]) => Promise<void>;
  restore: (items: CartLine[], mergeKey: string) => Promise<void>;
  canDiscardGuest: boolean; discardGuest: () => Promise<void>;
};
const CartContext = createContext<CartContextValue | null>(null);
function isFetchFailure(cause: unknown) {
  return cause instanceof TypeError || (typeof cause === "object" && cause !== null && "status" in cause && typeof cause.status === "number" && (cause.status === 0 || cause.status >= 500));
}
export function useCart() {
  const cart = useContext(CartContext);
  if (!cart) throw new Error("CartProvider chưa được khai báo");
  return cart;
}
export function CartProvider({ children }: { children: ReactNode }) {
  const auth = useAuth();
  const refreshAuth = auth.refresh;
  const authenticated = auth.status === "authenticated";
  const owner = authenticated ? `user:${String(auth.user?.id ?? auth.user?.email)}` : auth.status === "anonymous" ? "guest" : "waiting";
  const [snapshot, setSnapshot] = useState<{ owner: string; data: CartResponse; error: string; fetchFailed?: boolean; canDiscardGuest?: boolean }>({ owner: "", data: emptyCart, error: "" });
  const [busy, setBusy] = useState(false);
  const busyRef = useRef(false);
  const generation = useRef(0);
  const deferredLoad = useRef<(() => void) | null>(null);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const closeCart = useCallback(() => setDrawerOpen(false), []);
  const [excluded, setExcluded] = useState<{ owner: string; ids: number[] }>({ owner: "", ids: [] });
  const data = snapshot.owner === owner ? snapshot.data : emptyCart;
  const loading = auth.status !== "error" && (owner === "waiting" || snapshot.owner !== owner);
  const error = auth.status === "error" ? "Không thể kiểm tra phiên mua hàng. Vui lòng thử lại." : snapshot.owner === owner ? snapshot.error : "";
  const fetchFailed = auth.status === "error" ? isFetchFailure(auth.error) : snapshot.owner === owner && !!snapshot.fetchFailed;

  const load = useCallback(async (signal?: AbortSignal) => {
    if (owner === "waiting") return;
    if (busyRef.current) { deferredLoad.current = () => { void load(signal); }; return; }
    const epoch = ++generation.current;
    try {
      const result = await withCartStorageLock(async () => {
        if (signal?.aborted) throw new DOMException("Aborted", "AbortError");
        const guest = readGuestCart();
        if (authenticated) {
          if (guest.items.length && guest.importOwner && guest.importOwner !== owner) throw new Error("Giỏ trên máy đang chờ xác nhận gộp vào tài khoản trước. Hãy đăng nhập lại tài khoản đó hoặc xóa giỏ trên máy.");
          if (guest.items.length) writeGuestCart({ ...guest, importOwner: owner });
          const merged = guest.items.length ? await mergeCart(guest.mergeKey, guest.items, signal) : await getCart(signal);
          if (guest.items.length) clearMergedGuestCart(guest.mergeKey);
          return merged;
        }
        if (guest.items.length && guest.importOwner) throw new Error("Giỏ trên máy đang chờ xác nhận gộp vào tài khoản. Hãy đăng nhập lại tài khoản đó hoặc xóa giỏ trên máy.");
        return guest.items.length ? quoteCart(guest.items, signal) : emptyCart;
      });
      if (!signal?.aborted && epoch === generation.current) setSnapshot({ owner, data: result, error: "" });
    } catch (cause) {
      if (!signal?.aborted && epoch === generation.current) {
        setSnapshot(previous => ({ owner, data: previous.owner === owner ? previous.data : emptyCart, error: cause instanceof Error ? cause.message : "Không tải được giỏ hàng", fetchFailed: isFetchFailure(cause), canDiscardGuest: readGuestCart().items.length > 0 }));
        if (typeof cause === "object" && cause && "status" in cause && cause.status === 401) void refreshAuth().catch(() => {});
      }
    }
  }, [owner, authenticated, refreshAuth]);

  useEffect(() => {
    generation.current++;
    const controller = new AbortController();
    void load(controller.signal);
    const refresh = () => { if (!busyRef.current) void load(controller.signal); };
    const storage = (event: StorageEvent) => { if (event.key === GUEST_CART_KEY && !authenticated) refresh(); };
    window.addEventListener("focus", refresh);
    window.addEventListener("storage", storage);
    return () => { controller.abort(); window.removeEventListener("focus", refresh); window.removeEventListener("storage", storage); };
  }, [load, authenticated]);

  const mutate = async (path: string, method: string, body: object | undefined, transform: (lines: CartLine[]) => CartLine[], validateId?: number) => {
    if (loading || busyRef.current || error) throw new Error(error || "Vui lòng đợi giỏ hàng tải xong");
    busyRef.current = true; setBusy(true);
    const epoch = ++generation.current;
    let failed = false;
    try {
      const result = await withCartStorageLock(async () => {
        if (authenticated) return mutateCart(path, method, body);
        const guest = readGuestCart();
        if (guest.importOwner) throw new Error("Vui lòng đăng nhập lại để xác nhận gộp giỏ trước khi chỉnh sửa");
        const items = transform(guest.items);
        const result = await quoteCart(items);
        const changed = result.items.find(i => i.variantId === validateId);
        if (changed && !changed.purchasable) throw new Error(changed.unavailableReason || "Sản phẩm không thể mua");
        if (epoch !== generation.current) throw new Error("Phiên đăng nhập đã thay đổi, vui lòng thử lại");
        writeGuestCart({ ...guest, items });
        return result;
      });
      if (epoch === generation.current) setSnapshot({ owner, data: result, error: "" });
    } catch (cause) {
      failed = true;
      if (typeof cause === "object" && cause && "status" in cause && cause.status === 401) void auth.refresh().catch(() => {});
      throw cause;
    } finally { busyRef.current = false; setBusy(false); const deferred = deferredLoad.current; deferredLoad.current = null; if (deferred) deferred(); else if (failed) void load(); }
  };

  const refresh = useCallback(async () => {
    if (auth.status === "error") await refreshAuth().catch(() => {});
    else await load();
  }, [auth.status, refreshAuth, load]);

  const value: CartContextValue = {
    ...data, loading, busy, error, fetchFailed, drawerOpen,
    canDiscardGuest: snapshot.owner === owner && !!snapshot.canDiscardGuest,
    discardGuest: async () => {
      try { await withCartStorageLock(async () => { localStorage.removeItem(GUEST_CART_KEY); }); await load(); }
      catch (cause) { setSnapshot({ owner, data, error: cause instanceof Error ? cause.message : "Không xóa được giỏ trên máy" }); }
    },
    openCart: () => { setDrawerOpen(true); void load(); }, closeCart,
    refresh,
    selectedIds: data.items.filter(i => excluded.owner !== owner || !excluded.ids.includes(i.variantId)).map(i => i.variantId),
    selectedItems: data.items.filter(i => excluded.owner !== owner || !excluded.ids.includes(i.variantId)),
    selectedSubtotal: data.items.filter(i => excluded.owner !== owner || !excluded.ids.includes(i.variantId)).reduce((sum, i) => sum + i.lineTotal, 0),
    toggleSelected: id => setExcluded(previous => {
      const ids = previous.owner === owner ? previous.ids : [];
      return { owner, ids: ids.includes(id) ? ids.filter(i => i !== id) : [...ids, id] };
    }),
    add: (variantId, quantity) => mutate("/items", "POST", { variantId, quantity }, lines => {
      const existing = lines.find(i => i.variantId === variantId);
      return existing ? lines.map(i => i.variantId === variantId ? { ...i, quantity: i.quantity + quantity } : i) : [...lines, { variantId, quantity }];
    }, variantId),
    update: (variantId, quantity) => mutate(`/items/${variantId}`, "PATCH", { quantity }, lines => lines.map(i => i.variantId === variantId ? { ...i, quantity } : i), variantId),
    remove: variantId => mutate(`/items/${variantId}`, "DELETE", undefined, lines => lines.filter(i => i.variantId !== variantId)),
    replace: (variantId, nextVariantId, quantity) => mutate(`/items/${variantId}`, "PUT", { variantId: nextVariantId, quantity }, lines => {
      const remaining = lines.filter(i => i.variantId !== variantId);
      const existing = remaining.find(i => i.variantId === nextVariantId);
      return existing ? remaining.map(i => i.variantId === nextVariantId ? { ...i, quantity: i.quantity + quantity } : i) : [...remaining, { variantId: nextVariantId, quantity }];
    }, nextVariantId),
    clear: () => mutate("/items", "DELETE", undefined, () => []),
    consumeGuest: async purchased => {
      if (authenticated) return;
      await withCartStorageLock(async () => {
        const guest = readGuestCart();
        const items = guest.items.map(i => ({ ...i, quantity: i.quantity - purchased.filter(p => p.variantId === i.variantId).reduce((sum, p) => sum + p.quantity, 0) })).filter(i => i.quantity > 0);
        writeGuestCart({ ...guest, items });
      });
    },
    restore: async (purchased, mergeKey) => {
      if (loading || busyRef.current) throw new Error("Vui lòng đợi giỏ hàng tải xong");
      busyRef.current = true; setBusy(true);
      const epoch = ++generation.current;
      try {
        const result = await withCartStorageLock(async () => {
          if (authenticated) return mergeCart(mergeKey, purchased);
          const guest = readGuestCart();
          const quantities = new Map(guest.items.map(i => [i.variantId, i.quantity]));
          if (!guest.restoredKeys?.includes(mergeKey)) purchased.forEach(i => {
            const quantity = (quantities.get(i.variantId) || 0) + i.quantity;
            if (quantity > 999) throw new Error("Số lượng sau khi khôi phục vượt 999. Vui lòng giảm số lượng trong giỏ trước.");
            quantities.set(i.variantId, quantity);
          });
          const items = [...quantities].map(([variantId, quantity]) => ({ variantId, quantity }));
          const result = await quoteCart(items);
          if (epoch !== generation.current) throw new Error("Phiên đăng nhập đã thay đổi, vui lòng thử lại");
          writeGuestCart({ ...guest, items, restoredKeys: [...new Set([...(guest.restoredKeys || []), mergeKey])] });
          return result;
        });
        if (epoch === generation.current) setSnapshot({ owner, data: result, error: "" });
      } finally { busyRef.current = false; setBusy(false); const deferred = deferredLoad.current; deferredLoad.current = null; if (deferred) deferred(); }
    },
  };
  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}
