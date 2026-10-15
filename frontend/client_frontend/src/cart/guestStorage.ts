import type { CartLine } from "./types";

export const GUEST_CART_KEY = "zella.guest-cart.v1";
type GuestCart = { mergeKey: string; items: CartLine[]; restoredKeys?: string[]; importOwner?: string };
export function readGuestCart(): GuestCart {
  const fallback = { mergeKey: crypto.randomUUID(), items: [] };
  try {
    const stored = JSON.parse(localStorage.getItem(GUEST_CART_KEY) || "null");
    if (!stored || !Array.isArray(stored.items) || !/^[a-f0-9-]{36}$/i.test(stored.mergeKey)) return fallback;
    const items: CartLine[] = [];
    for (const line of stored.items.slice(0, 200)) {
      if (Number.isSafeInteger(line.variantId) && line.variantId > 0 && Number.isInteger(line.quantity) && line.quantity > 0 && line.quantity <= 999)
        items.push({ variantId: line.variantId, quantity: line.quantity });
    }
    return { mergeKey: stored.mergeKey, items, importOwner: typeof stored.importOwner === "string" ? stored.importOwner : undefined, restoredKeys: Array.isArray(stored.restoredKeys) ? stored.restoredKeys.filter((key: unknown) => typeof key === "string") : [] };
  } catch { return fallback; }
}
export function writeGuestCart(cart: GuestCart) { localStorage.setItem(GUEST_CART_KEY, JSON.stringify(cart)); }
export function clearMergedGuestCart(mergeKey: string) {
  if (readGuestCart().mergeKey === mergeKey) localStorage.removeItem(GUEST_CART_KEY);
}

// Serialize local reads/writes with login imports, including other tabs on the same origin.
export async function withCartStorageLock<T>(task: () => Promise<T>): Promise<T> {
  if (navigator.locks) return navigator.locks.request("zella-cart-storage", task);
  return task();
}
