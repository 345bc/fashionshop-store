"use client";
import GoogleSymbol from "@/components/ui/GoogleSymbol";


import { useEffect, useRef, useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";

const CopyableCode = ({ code }: { code: string }) => {
  const [copied, setCopied] = useState(false);
  const handleCopy = () => {
    navigator.clipboard.writeText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };
  return (
    <span
      className="inline-flex items-center gap-1.5 cursor-pointer text-black hover:text-gray-700 bg-gray-100 hover:bg-gray-200 px-2 py-0.5 rounded transition-colors"
      onClick={handleCopy}
      title="Copy mã đơn"
    >
      <span className="tracking-wide font-medium">{code}</span>
      {copied ? (
        <GoogleSymbol name="check" size={14} className="text-green-600" />
      ) : (
        <GoogleSymbol name="content_copy" size={14} className="text-gray-500" />
      )}
    </span>
  );
};
import { clearCheckoutFlow, completeCheckoutFlow } from "@/service/checkoutFlowService";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import { useAuth } from "@/auth/AuthContext";
import { useCart } from "@/cart/CartContext";
import { money, type CartItem, type PendingCheckout, type CheckoutPrice } from "@/cart/types";
import { checkoutStatus, createCheckout, quoteCheckout, verifyCheckoutReturn } from "@/service/cartService";
import { getIdByUserId } from "@/service/customerApi";
import CheckoutItems from "./CheckoutItems";
import CheckoutPayment from "./CheckoutPayment";
import CheckoutAddressFields from "./CheckoutAddressFields";
import CheckoutOrderDialog from "./CheckoutOrderDialog";
import CheckoutSummary from "./CheckoutSummary";

type StoredOrder = { owner: string; order: PendingCheckout; items: CartItem[]; restoreKey: string; savedAt?: number };
type CheckoutDraft = { owner: string; request: Parameters<typeof createCheckout>[0]; items: CartItem[]; restoreKey: string };
const STORAGE_KEY = "zella.pending-checkout.v1";
const DRAFT_KEY = "zella.checkout-draft.v1";
function saveOrder(value: StoredOrder) { sessionStorage.setItem(STORAGE_KEY, JSON.stringify(value)); }
function getStoredOrder(owner: string): StoredOrder | null {
  try {
    const stored = JSON.parse(sessionStorage.getItem(STORAGE_KEY) || "null");
    if (!stored || stored.owner !== owner || !stored.order?.checkoutToken || !stored.order?.code || !Array.isArray(stored.items)) {
      return null;
    }
    const isFinished = stored.order.paymentStatus === "PAID" || stored.order.status === "CANCELLED";
    if (isFinished && stored.savedAt && Date.now() - stored.savedAt > 30 * 60 * 1000) {
      sessionStorage.removeItem(STORAGE_KEY);
      return null;
    }
    return stored;
  } catch { return null; }
}

export default function CheckoutPage() {
  const router = useRouter();
  const auth = useAuth();
  const cart = useCart();
  const owner = auth.status === "authenticated" ? `user:${String(auth.user?.id ?? auth.user?.email)}` : auth.status === "anonymous" ? "guest" : "waiting";

  // Checkout form states
  const [form, setForm] = useState({
    recipientName: "",
    recipientPhone: "",
    recipientEmail: "",
    street: "",
    apartment: "",
    city: "",
    ward: "",
    note: ""
  });

  useEffect(() => {
    let active = true;
    if (auth.status === "authenticated" && auth.user?.id) {
      getIdByUserId(auth.user.id).then(response => {
        if (!active) return;
        const profile = response.data;
        if (!profile) return;
        setForm(f => {
          // Only prefill if the form is completely empty (user hasn't typed anything yet)
          if (f.recipientName || f.recipientPhone || f.street || f.city || f.ward) return f;

          let street = profile.address || "";
          let ward = "";
          let city = "";

          if (street) {
            const parts = street.split(",").map((s: string) => s.trim());
            if (parts.length >= 3) {
              city = parts[parts.length - 1];
              ward = parts[parts.length - 2];
              street = parts.slice(0, parts.length - 2).join(", ");
            }
          }

          return {
            ...f,
            recipientName: profile.fullName || profile.fullname || "",
            recipientPhone: profile.phone || "",
            recipientEmail: String(auth.user?.email || ""),
            street,
            ward,
            city,
          };
        });
      }).catch(() => { /* ignore */ });
    }
    return () => { active = false; };
  }, [auth.status, auth.user]);


  const [shipping, setShipping] = useState("STANDARD");
  const deliveryInfoReady = form.recipientName.trim().length > 0
    && form.recipientName.trim().length <= 150
    && form.street.trim().length > 0
    && !!form.city && !!form.ward
    && /^0[0-9]{9}$/.test(form.recipientPhone.trim())
    && [form.street, form.apartment, form.ward, form.city].filter(Boolean).join(", ").trim().length <= 350;
  const [payment, setPayment] = useState("VNPAY");
  const [voucherCode, setVoucherCode] = useState("");
  const [appliedVoucherCode, setAppliedVoucherCode] = useState("");
  const [quoteAttempt, setQuoteAttempt] = useState(0);
  const [quoteResult, setQuoteResult] = useState<{ key: string; pricing?: CheckoutPrice; error?: string } | null>(null);

  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const submittingRef = useRef(false);
  const [restoring, setRestoring] = useState(false);
  const [stored, setStored] = useState<StoredOrder | null>(null);
  const [draft, setDraft] = useState<CheckoutDraft | null>(null);
  const [hydratedOwner, setHydratedOwner] = useState("");
  const [now, setNow] = useState(0);
  const [closedDialogKey, setClosedDialogKey] = useState("");

  const isFinished = stored?.order.paymentStatus === "PAID" || stored?.order.status === "CANCELLED";
  const hasNewCartItems = cart.selectedItems.length > 0 && cart.selectedItems.every(i => i.purchasable);
  const pending = stored?.owner === owner && !(isFinished && hasNewCartItems) ? stored : null;
  const orderCode = pending?.order.code;
  const orderToken = pending?.order.checkoutToken;
  const orderStatus = pending?.order.status;
  const paymentStatus = pending?.order.paymentStatus;
  const activeDraft = draft?.owner === owner ? draft : null;
  const checkoutItems = pending?.items ?? activeDraft?.items ?? cart.selectedItems;
  const quoteItems = JSON.stringify(checkoutItems.map(item => ({ variantId: item.variantId, quantity: item.quantity })));
  const quoteKey = JSON.stringify([owner, shipping, appliedVoucherCode, quoteItems, checkoutItems.map(item => item.unitPrice), quoteAttempt]);
  const currentQuote = quoteResult?.key === quoteKey ? quoteResult : null;
  const pricing = pending?.order.pricing ?? currentQuote?.pricing;
  const subtotal = pricing?.subtotal ?? pending?.order.subtotal ?? checkoutItems.reduce((sum, item) => sum + item.lineTotal, 0);
  const estimatedShippingFee = subtotal >= 600000 ? 0 : 30000;
  const shippingFee = pricing?.shippingFee ?? pending?.order.shippingFee ?? estimatedShippingFee;
  const discount = pricing?.discountAmount ?? pending?.order.discountAmount ?? 0;
  const priceError = !pending && !activeDraft ? currentQuote?.error ?? "" : "";
  const quoteLoading = !pending && !activeDraft && !currentQuote;
  const quoteReady = !!currentQuote?.pricing;
  const enteredVoucherCode = voucherCode.trim().toUpperCase();
  const voucherBusy = quoteLoading && !!appliedVoucherCode;
  const voucherNeedsApply = !!enteredVoucherCode && enteredVoucherCode !== appliedVoucherCode;
  const voucherError = appliedVoucherCode ? priceError : "";
  const canSubmitQuote = quoteReady && !voucherNeedsApply && !voucherBusy && !voucherError;

  function applyVoucher() {
    if (!deliveryInfoReady || submitting || voucherBusy || activeDraft) return;
    setAppliedVoucherCode(enteredVoucherCode);
    setQuoteAttempt(value => value + 1);
  }
  useEffect(() => {
    const controller = new AbortController();
    if (pending || activeDraft || owner === "waiting" || !JSON.parse(quoteItems).length) return () => controller.abort();
    quoteCheckout(JSON.parse(quoteItems), shipping, appliedVoucherCode, controller.signal)
      .then(pricing => { if (!controller.signal.aborted) setQuoteResult({ key: quoteKey, pricing }); })
      .catch(cause => { if (!controller.signal.aborted) setQuoteResult({ key: quoteKey, error: cause instanceof Error ? cause.message : "Không tải được số tiền thanh toán." }); });
    return () => controller.abort();
  }, [quoteKey, quoteItems, shipping, appliedVoucherCode, owner, pending, activeDraft]);
  const dialogKey = pending ? `${pending.order.code}:${pending.order.status}:${pending.order.paymentStatus}` : "";
  const validCart = !cart.loading && !cart.busy && !cart.error && cart.selectedItems.length > 0 && cart.selectedItems.every(i => i.purchasable);
  const checkingCart = !pending && !activeDraft && (cart.loading || cart.busy);
  const emptyCheckout = owner !== "waiting" && hydratedOwner === owner && !pending && !activeDraft
    && !cart.loading && !cart.busy && !cart.error && cart.selectedItems.length === 0;

  useEffect(() => {
    if (owner === "waiting") return;
    const timer = setTimeout(() => {
      const savedOrder = getStoredOrder(owner);
      const isFinishedOrder = savedOrder?.order.paymentStatus === "PAID" || savedOrder?.order.status === "CANCELLED";
      const hasNewCart = cart.selectedItems.length > 0 && cart.selectedItems.every(i => i.purchasable);
      if (savedOrder && isFinishedOrder && hasNewCart) {
        sessionStorage.removeItem(STORAGE_KEY);
        sessionStorage.removeItem(DRAFT_KEY);
        setStored(null);
      } else {
        setStored(savedOrder);
      }
      setNow(Date.now());
      try {
        const saved = JSON.parse(sessionStorage.getItem(DRAFT_KEY) || "null") as CheckoutDraft | null;
        const valid = saved?.owner === owner && saved.request?.checkoutKey && Array.isArray(saved.items) && saved.items.length > 0
          && Array.isArray(saved.request.items) && saved.request.items.length > 0 ? saved : null;
        setDraft(valid);
        if (valid) {
          setForm(f => ({ ...f, recipientName: valid.request.recipientName, recipientPhone: valid.request.recipientPhone, recipientEmail: valid.request.recipientEmail || "", note: valid.request.note || "", street: valid.request.address }));
          setShipping(valid.request.shippingMethod);
        }
      } catch { setDraft(null); }
      setHydratedOwner(owner);
    }, 0);
    return () => clearTimeout(timer);
  }, [owner, cart.selectedItems]);

  useEffect(() => {
    if (!emptyCheckout || submittingRef.current) return;
    let active = true;
    // The cart lives in the browser for guests; a previously signed cookie can outlive its contents.
    void clearCheckoutFlow().catch(() => undefined).finally(() => {
      if (active) router.replace("/products");
    });
    return () => { active = false; };
  }, [emptyCheckout, router]);

  useEffect(() => {
    if (!orderCode || !orderToken || !orderStatus || !["PENDING", "CANCELLED"].includes(orderStatus) || paymentStatus === "REFUNDED") return;
    let active = true, polling = false;
    const tick = setInterval(() => setNow(Date.now()), 1000);
    const poll = async () => {
      if (polling) return;
      polling = true;
      try {
        const url = new URL(window.location.href);
        const returnParams = new URLSearchParams();
        url.searchParams.forEach((value, key) => {
          if (key.startsWith("vnp_")) returnParams.append(key, value);
        });
        if (returnParams.has("vnp_SecureHash")) {
          await verifyCheckoutReturn({ code: orderCode, checkoutToken: orderToken }, returnParams);
          if (!active) return;
          for (const key of new Set(returnParams.keys())) url.searchParams.delete(key);
          window.history.replaceState(window.history.state, "", url.pathname + url.search + url.hash);
        }
        const order = await checkoutStatus({ code: orderCode, checkoutToken: orderToken });
        if (order.paymentStatus === "PAID" && ["CONFIRMED", "SHIPPED", "DELIVERED"].includes(order.status)) {
          // A failed page-access grant must not hide a payment already confirmed by the backend.
          await completeCheckoutFlow(order).catch(() => undefined);
        }
        const current = getStoredOrder(owner);
        if (active && current?.order.code === orderCode && current.order.checkoutToken === orderToken) {
          const next = { ...current, order, savedAt: current.savedAt || Date.now() }; saveOrder(next); setStored(next); setError("");
        }
      } catch (cause) { if (active) setError(cause instanceof Error ? cause.message : "Không tải được trạng thái đơn"); }
      finally { polling = false; }
    };
    void poll();
    const timer = setInterval(() => void poll(), 5000);
    return () => { active = false; clearInterval(timer); clearInterval(tick); };
  }, [orderCode, orderToken, orderStatus, paymentStatus, owner]);

  function startNewOrder() {
    sessionStorage.removeItem(STORAGE_KEY);
    sessionStorage.removeItem(DRAFT_KEY);
    setStored(null);
    void clearCheckoutFlow().catch(() => undefined);
    if (cart.selectedItems.length > 0) {
      setClosedDialogKey(dialogKey);
    } else {
      router.push("/products");
    }
  }

  async function submit(event: FormEvent) {
    event.preventDefault();
    if (submittingRef.current || (!canSubmitQuote && !activeDraft) || (!validCart && !activeDraft) || hydratedOwner !== owner) return;
    if (!/^0[0-9]{9}$/.test(form.recipientPhone.trim())) { setError("Số điện thoại phải gồm 10 chữ số, bắt đầu bằng 0"); return; }
    submittingRef.current = true; setSubmitting(true); setError("");
    const items = activeDraft?.items ?? cart.selectedItems.map(i => ({ ...i }));

    if (!activeDraft && (!form.city || !form.ward)) {
      setError("Vui lòng chọn tỉnh/thành phố và phường/xã");
      document.getElementById("checkout-address-fields")?.scrollIntoView({ behavior: "smooth", block: "center" });
      submittingRef.current = false; setSubmitting(false); return;
    }
    const fullAddress = [form.street, form.apartment, form.ward, form.city].filter(Boolean).join(", ");
    if (fullAddress.trim().length > 350) {
      setError("Địa chỉ không được dài quá 350 ký tự");
      submittingRef.current = false; setSubmitting(false); return;
    }

    try {
      const attempt = activeDraft ?? { owner, items, restoreKey: crypto.randomUUID(), request: { recipientName: form.recipientName.trim(), recipientPhone: form.recipientPhone.trim(), recipientEmail: form.recipientEmail.trim() || undefined, address: fullAddress.trim() || form.street.trim(), note: form.note.trim(), shippingMethod: shipping, items: items.map(i => ({ variantId: i.variantId, quantity: i.quantity })), checkoutKey: crypto.randomUUID(), voucherCode: appliedVoucherCode } };
      sessionStorage.setItem(DRAFT_KEY, JSON.stringify(attempt)); setDraft(attempt);
      const order = await createCheckout(attempt.request);
      const pricedItems = order.items.map(line => ({ ...items.find(i => i.variantId === line.variantId)!, ...line }));
      const next = { owner, order, items: pricedItems, restoreKey: attempt.restoreKey, savedAt: Date.now() };
      saveOrder(next); setStored(next); setNow(Date.now());
      sessionStorage.removeItem(DRAFT_KEY); setDraft(null);
      await cart.consumeGuest(items);
      await cart.refresh();
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Không đặt được hàng");
      if (typeof cause === "object" && cause && (("status" in cause && typeof cause.status === "number" && cause.status >= 400 && cause.status < 500)
        || ("code" in cause && cause.code === "PAYMENT_NOT_CONFIGURED"))) { sessionStorage.removeItem(DRAFT_KEY); setDraft(null); }
      await cart.refresh();
    } finally { submittingRef.current = false; setSubmitting(false); }
  }

  async function returnToCart() {
    if (!pending || restoring) return;
    setRestoring(true); setError("");
    try {
      const order = pending.order.status === "PENDING" ? await checkoutStatus(pending.order, true) : pending.order;
      const next = { ...pending, order }; saveOrder(next); setStored(next);
      await cart.restore(pending.items, pending.restoreKey);
      sessionStorage.removeItem(STORAGE_KEY);
      setStored(null);
      cart.openCart();
    } catch (cause) { setError(cause instanceof Error ? cause.message : "Không quay lại được giỏ hàng"); }
    finally { setRestoring(false); }
  }
  const paid = pending?.order.paymentStatus === "PAID";
  const cancelled = pending?.order.status === "CANCELLED";
  const remaining = pending && now ? Math.max(0, Math.ceil((Date.parse(pending.order.paymentExpiresAt) - now) / 1000)) : 300;
  const orderTitle = paid ? "Đã thanh toán thành công" : paymentStatus === "REFUND_PENDING" ? "Đang chờ hoàn tiền" : cancelled ? "Đơn hàng đã hủy" : "Đang chờ thanh toán";

  return (
    <>
      <Header />
      <main className="container mx-auto px-5 lg:px-10 py-10 lg:py-16 min-h-[65vh] font-sans text-gray-900">

        {owner === "waiting" || hydratedOwner !== owner || checkingCart || emptyCheckout ? (
          <p className="py-12 text-center text-sm text-gray-500 uppercase tracking-wider">Đang tải...</p>
        ) : pending ? (
          <>
            <div className="grid grid-cols-1 lg:grid-cols-[1fr_420px] xl:grid-cols-[1fr_460px] gap-12 lg:gap-20 items-start">
              <section>
                <h1 className="text-2xl font-semibold mb-3">{orderTitle}</h1>
                <p className="text-sm text-gray-500 mb-6 flex items-center gap-2">Mã đơn: <CopyableCode code={pending.order.code} /></p>
                <div className="flex flex-wrap gap-3">
                  <button type="button" className="px-6 py-3 bg-black text-white rounded font-semibold hover:bg-gray-800 transition-colors"
                    onClick={() => setClosedDialogKey("")}>{paid || cancelled ? "Xem trạng thái đơn" : "Tiếp tục thanh toán"}</button>
                  {paid && (
                    <>
                      <button
                        type="button"
                        className="px-6 py-3 bg-white text-black border border-gray-300 rounded font-semibold hover:bg-gray-100 transition-colors"
                        onClick={startNewOrder}
                      >
                        {cart.selectedItems.length > 0 ? "Thanh toán giỏ hàng mới" : "Đặt đơn hàng mới"}
                      </button>
                      <Link
                        href="/orders"
                        className="px-6 py-3 bg-gray-100 text-gray-800 rounded font-semibold hover:bg-gray-200 transition-colors inline-flex items-center"
                      >
                        Lịch sử đơn hàng
                      </Link>
                    </>
                  )}
                </div>
              </section>
              <CheckoutSummary items={pending.items} subtotal={subtotal} shippingFee={shippingFee} total={pending.order.totalAmount} discount={discount} pricing={pricing} />
            </div>
            <CheckoutOrderDialog open={closedDialogKey !== dialogKey} title={orderTitle} busy={restoring}
              onClose={() => setClosedDialogKey(dialogKey)}>
              <p className="text-sm text-gray-500 mb-6 flex items-center gap-2">Mã đơn: <CopyableCode code={pending.order.code} /></p>
              {!paid && !cancelled && (
                <>
                  <div className="text-5xl font-light tabular-nums text-black leading-none tracking-tight mb-4" aria-label="Thời gian còn lại">
                    {Math.floor(remaining / 60)}:{String(remaining % 60).padStart(2, "0")}
                  </div>
                  <p className="normal-caption">
                    Hàng được giữ trong 5 phút. Chưa thanh toán khi hết hạn, hệ thống tự hủy đơn và giải phóng hàng.
                  </p>
                  <div className="text-sm text-gray-600 bg-white p-4 rounded-lg border border-gray-200 shadow-sm mb-6">
                    {remaining > 0 ? <CheckoutPayment order={pending.order} /> : "Đã hết thời gian thanh toán. Đang cập nhật trạng thái đơn."}
                  </div>
                </>
              )}
              {cancelled && (
                <p className="text-sm text-gray-500 mb-6 leading-relaxed">
                  Hàng đã được giải phóng. Bạn có thể đưa sản phẩm về giỏ và kiểm tra tồn kho lại.
                </p>
              )}
              {pending.order.paymentStatus === "REFUND_PENDING" && <p className="text-sm text-gray-600 mb-6">Tiền đã về sau khi đơn hủy. Cửa hàng sẽ kiểm tra và hoàn tiền; đơn này không được giao.</p>}
              <div className="mt-8">
                <CheckoutItems items={pending.items} />
              </div>
              <div className="flex justify-between items-baseline py-6 border-t border-gray-200 mt-6">
                <span className="text-sm font-medium">Tổng tiền đơn hàng</span>
                <strong className="text-2xl font-bold">{money(pending.order.totalAmount)}</strong>
              </div>
              {!paid && (pending.order.status === "PENDING" || cancelled) && (
                <button
                  className="w-full py-4 bg-black text-white rounded-lg text-sm font-medium hover:bg-gray-900 transition-colors disabled:opacity-50"
                  disabled={restoring || cart.loading || cart.busy}
                  onClick={() => void returnToCart()}
                >
                  {restoring ? "Đang xử lý..." : cancelled ? "Đưa sản phẩm về giỏ" : "Hủy đơn và quay lại sửa giỏ"}
                </button>
              )}
              {paid && (
                <>
                  <p className="text-sm text-gray-500 bg-white p-4 rounded-lg border border-gray-200 mb-6 leading-relaxed">
                    Đơn hàng đã được tự động xác nhận. Nội dung đơn đã thanh toán được giữ nguyên.
                  </p>
                  <div className="flex flex-col sm:flex-row gap-3">
                    <button
                      className="flex-1 py-4 bg-black text-white rounded-lg text-sm font-medium hover:bg-gray-900 transition-colors"
                      onClick={startNewOrder}
                    >
                      {cart.selectedItems.length > 0 ? "Thanh toán giỏ hàng mới" : "Đặt đơn hàng mới"}
                    </button>
                    <Link
                      href="/orders"
                      className="py-4 px-6 text-center border border-gray-300 text-gray-800 rounded-lg text-sm font-medium hover:bg-gray-50 transition-colors"
                    >
                      Xem đơn hàng
                    </Link>
                  </div>
                </>
              )}
              <p className="mt-5 text-sm leading-6 text-black/55">Lưu mã đơn để <Link href="/order-tracking" className="font-medium text-black underline underline-offset-4">tra cứu đơn hàng</Link> bằng số điện thoại nhận hàng.</p>
              {error && <p role="alert" className="mt-4 text-sm text-red-600 bg-red-50 border-l-4 border-red-600 p-3">{error}</p>}
            </CheckoutOrderDialog>
          </>
        ) : !activeDraft && cart.error ? (
          <div className="py-12 text-center">
            <p role="alert" className="text-sm text-gray-600">Không kiểm tra được giỏ hàng. Vui lòng thử lại.</p>
            <button type="button" className="mt-4 rounded border border-black/20 px-5 py-2 text-sm font-medium" onClick={() => void cart.refresh()}>Thử lại</button>
          </div>
        ) : (
          <form className="grid grid-cols-1 lg:grid-cols-[1fr_420px] xl:grid-cols-[1fr_460px] gap-12 lg:gap-20 items-start" onSubmit={submit}>
            {/* Cột trái: Thông tin Giao hàng & Thanh toán */}
            <div className="flex flex-col gap-10 min-w-0">

              <fieldset disabled={submitting || !!activeDraft} className="flex flex-col gap-10">
                {/* Giao hàng */}
                <section>
                  <h2 className="text-[22px] font-normal text-gray-900 mb-6">Thông Tin giao hàng</h2>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">

                    <div className="md:col-span-2">
                      <input required maxLength={150} autoComplete="name" value={form.recipientName} onChange={e => setForm({ ...form, recipientName: e.target.value })}
                        className="w-full border border-gray-300 rounded-lg px-4 py-3.5 text-[15px] font-medium text-gray-900 placeholder-gray-500 focus:ring-2 focus:ring-black focus:border-black outline-none transition-all"
                        placeholder="Họ tên" />
                    </div>

                    <div className="md:col-span-2">
                      <input required maxLength={350} autoComplete="street-address" value={form.street} onChange={e => setForm({ ...form, street: e.target.value })}
                        className="w-full border border-gray-300 rounded-lg px-4 py-3.5 text-[15px] font-medium text-gray-900 placeholder-gray-500 focus:ring-2 focus:ring-black focus:border-black outline-none transition-all"
                        placeholder="Địa chỉ" />
                    </div>

                    <div className="md:col-span-2">
                      <input maxLength={200} value={form.apartment} onChange={e => setForm({ ...form, apartment: e.target.value })}
                        className="w-full border border-gray-300 rounded-lg px-4 py-3.5 text-[15px] font-medium text-gray-900 placeholder-gray-500 focus:ring-2 focus:ring-black focus:border-black outline-none transition-all"
                        placeholder="Căn hộ, phòng, v.v. (không bắt buộc)" />
                    </div>

                    <CheckoutAddressFields city={form.city} ward={form.ward}
                      onChange={(city, ward) => {
                        setForm(current => ({ ...current, city, ward }));
                        if (error === "Vui lòng chọn tỉnh/thành phố và phường/xã") setError("");
                      }}
                      showError={error === "Vui lòng chọn tỉnh/thành phố và phường/xã"}
                    />

                    <div className="md:col-span-2">
                      <input required type="tel" maxLength={10} pattern="0[0-9]{9}" title="Số điện thoại phải có 10 chữ số và bắt đầu bằng 0" autoComplete="tel" value={form.recipientPhone} onChange={e => setForm({ ...form, recipientPhone: e.target.value })}
                        className="w-full border border-gray-300 rounded-lg px-4 py-3.5 text-[15px] font-medium text-gray-900 placeholder-gray-500 focus:ring-2 focus:ring-black focus:border-black outline-none transition-all"
                        placeholder="Số điện thoại" />
                    </div>

                    <div className="md:col-span-2">
                      <label className="block mb-4">
                        <span className="block mb-2 text-sm">Email nhận thông tin đơn hàng (không bắt buộc)</span>
                        <input type="email" maxLength={254} autoComplete="email" value={form.recipientEmail} onChange={e => setForm({ ...form, recipientEmail: e.target.value })}
                          className="w-full border border-gray-300 rounded-lg px-4 py-3.5 text-[15px] text-gray-900" placeholder="you@gmail.com" />
                      </label>
                      <textarea rows={3} maxLength={500} value={form.note} onChange={e => setForm({ ...form, note: e.target.value })}
                        className="w-full border border-gray-300 rounded-lg px-4 py-3.5 text-[15px] font-medium text-gray-900 placeholder-gray-500 focus:ring-2 focus:ring-black focus:border-black outline-none transition-all resize-none"
                        placeholder="Ghi chú đơn hàng" />
                    </div>
                  </div>
                </section>

                {/* Phương thức vận chuyển */}
                <section>
                  <h2 className="normal-title">Phương thức vận chuyển</h2>
                  <div className={`rounded-lg overflow-hidden transition-all ${shipping === "STANDARD" ? "border border-black bg-gray-50/80" : "border border-gray-300"}`}>
                    <label className="flex items-center gap-3 p-4 cursor-pointer transition-colors hover:bg-gray-50">
                      <input type="radio" name="shipping" checked={shipping === "STANDARD"} onChange={() => setShipping("STANDARD")} className="w-5 h-5 accent-black" />
                      <span className="text-[15px] font-normal text-gray-900 flex-1">Giao hàng tiêu chuẩn</span>
                      <span className="text-[15px] font-medium text-gray-900">{money(shippingFee)}</span>
                    </label>
                  </div>
                </section>

                {/* Thanh toán */}
                <section>
                  <div className="mb-4">
                    <h2 className="text-[22px] font-normal text-gray-900 mb-6">Thanh toán</h2>
                    <p className="text-sm text-gray-500 font-normal">Đơn được giữ hàng 5 phút để thanh toán. Hết hạn chưa thanh toán, đơn sẽ tự hủy.</p>
                  </div>

                  <div className={`rounded-lg overflow-hidden transition-all ${payment === "VNPAY" ? "border border-black bg-gray-50/80 shadow-sm" : "border border-gray-300"}`}>
                    <label className="flex items-center gap-4 p-4 cursor-pointer transition-all hover:bg-gray-50">
                      <input type="radio" name="payment" checked={payment === "VNPAY"} onChange={() => setPayment("VNPAY")} className="w-5 h-5 accent-black" />
                      <div className="flex flex-col flex-1">
                        <span className="text-[15px] font-medium text-gray-900">Thanh toán qua VNPAY</span>
                        <span className="text-[13px] text-gray-500 mt-0.5">Quét mã QR, Thẻ ATM nội địa hoặc thẻ quốc tế</span>
                      </div>
                      <div className="flex items-center bg-white px-2.5 py-1.5 rounded-md shadow-sm border border-gray-200 select-none">
                        <span className="font-black text-blue-700 text-[14px] italic tracking-tighter">VN</span>
                        <span className="font-black text-red-600 text-[14px] italic tracking-tighter">PAY</span>
                      </div>
                    </label>
                  </div>
                </section>

                <div className="mt-6">
                  <button type="submit" disabled={submitting || (!canSubmitQuote && !activeDraft) || (!validCart && !activeDraft)}
                    className="w-full py-3 bg-black text-white rounded-lg text-[14px] font-medium hover:bg-gray-800 transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
                    {submitting ? "Đang xử lý..." : activeDraft ? "Thử lại đặt hàng" : "Hoàn tất đơn hàng"}
                  </button>
                  {activeDraft && <p className="text-[13px] text-gray-600 mt-4 text-center">Chưa xác nhận được kết quả đặt hàng. Hãy thử lại để kiểm tra yêu cầu trước.</p>}
                  {!activeDraft && voucherNeedsApply && <p role="status" className="text-[13px] text-gray-600 mt-4 text-center">Vui lòng áp dụng mã giảm giá hoặc xóa mã để tiếp tục đặt hàng.</p>}
                  {!cart.loading && !cart.fetchFailed && !checkoutItems.length && <p className="text-[13px] text-red-600 mt-4 text-center">Chưa có sản phẩm được chọn. Vui lòng quay lại giỏ hàng.</p>}
                  {(error && error !== "Vui lòng chọn tỉnh/thành phố và phường/xã" || (cart.error && !cart.fetchFailed)) && <p className="text-[13px] text-red-700 mt-4 bg-red-50 p-4 rounded-md text-center" role="alert">{error && error !== "Vui lòng chọn tỉnh/thành phố và phường/xã" ? error : cart.error}</p>}
                </div>
              </fieldset>

            </div>

            {/* Cột phải: Tổng quan đơn hàng */}
            <CheckoutSummary items={checkoutItems} subtotal={subtotal} shippingFee={shippingFee} total={pricing?.totalAmount ?? subtotal + shippingFee - discount} discount={discount} pricing={pricing} pricesLoading={quoteLoading} priceError={priceError} onRetryPrice={() => setQuoteAttempt(value => value + 1)}
              voucherCode={activeDraft?.request.voucherCode ?? voucherCode} onVoucherChange={value => { if (!deliveryInfoReady || submitting || activeDraft) return; setVoucherCode(value); setAppliedVoucherCode(""); }} onApplyVoucher={() => void applyVoucher()} voucherBusy={voucherBusy} voucherDisabled={!deliveryInfoReady || submitting || !!activeDraft} voucherError={voucherError}
              voucherHint={!deliveryInfoReady && !activeDraft ? "Điền đủ họ tên, địa chỉ, tỉnh/thành phố, phường/xã và số điện thoại hợp lệ để nhập mã ưu đãi." : ""}
              loading={(cart.loading || cart.fetchFailed) && !activeDraft} />
          </form>
        )}
      </main>
      <Footer />
    </>
  );
}
