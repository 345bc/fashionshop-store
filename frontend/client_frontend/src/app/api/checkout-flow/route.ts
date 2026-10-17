import { NextRequest, NextResponse } from "next/server";
import { signWorkflow, verifyWorkflow, WORKFLOW_COOKIE } from "@/utils/server/workflowCookie";

const backend = (process.env.BACKEND_API_BASE_URL || process.env.NEXT_PUBLIC_API_BASE_URL || `${process.env.NEXT_PUBLIC_BACKEND_URL || "http://localhost:8080"}/api/v1`).replace(/\/$/, "");
function sameOrigin(request: NextRequest) { return request.headers.get("origin") === request.nextUrl.origin; }
function result(status: number, message: string) { return NextResponse.json({ message }, { status, headers: { "Cache-Control": "no-store" } }); }
const cookieOptions = { httpOnly: true, sameSite: "lax" as const, secure: process.env.NODE_ENV === "production", path: "/", maxAge: 3600 };

export async function POST(request: NextRequest) {
  if (!sameOrigin(request)) return result(403, "Yêu cầu không hợp lệ");
  if (Number(request.headers.get("content-length")) > 32768) return result(413, "Yêu cầu quá lớn");
  try {
    const body = await request.json();
    let phase: "checkout" | "paid" = "checkout";
    if (body.phase === "paid") {
      if (!verifyWorkflow(request.cookies.get(WORKFLOW_COOKIE)?.value)) return result(403, "Phiên đặt hàng không hợp lệ");
      if (typeof body.code !== "string" || !/^ORD-[A-Z0-9]{28}$/.test(body.code)
          || typeof body.checkoutToken !== "string" || body.checkoutToken.length > 100) return result(400, "Thông tin đơn không hợp lệ");
      const status = await fetch(`${backend}/checkout/orders/${encodeURIComponent(body.code)}`, {
        headers: { "X-Checkout-Token": body.checkoutToken }, cache: "no-store", signal: AbortSignal.timeout(5000),
      });
      if (!status.ok) return result(403, "Không xác minh được đơn hàng");
      const order = (await status.json()).data;
      if (order?.paymentStatus !== "PAID" || !["CONFIRMED", "SHIPPED", "DELIVERED"].includes(order.status)) return result(409, "Đơn chưa thanh toán thành công");
      phase = "paid";
    } else {
      if (body.phase !== "checkout" || !Array.isArray(body.items) || body.items.length < 1 || body.items.length > 200
          || body.items.some((item: { variantId?: number; quantity?: number } | null) => !item || !Number.isSafeInteger(item.variantId) || Number(item.variantId) < 1
            || !Number.isInteger(item.quantity) || Number(item.quantity) < 1 || Number(item.quantity) > 999)) return result(400, "Giỏ hàng không hợp lệ");
      // Obtain a backend CSRF pair for this server-side quote. No customer identity is needed.
      const csrf = await fetch(`${backend}/auth/csrf`, { cache: "no-store", signal: AbortSignal.timeout(5000) });
      if (!csrf.ok) return result(503, "Không kiểm tra được giỏ hàng");
      const csrfData = (await csrf.json()).data;
      const cookies = csrf.headers.getSetCookie().map(value => value.split(";")[0]).join("; ");
      if (!csrfData?.headerName || !csrfData?.token || !cookies) return result(503, "Không khởi tạo được phiên đặt hàng");
      const quote = await fetch(`${backend}/cart/quote`, {
        method: "POST", headers: { "Content-Type": "application/json", Cookie: cookies, [csrfData.headerName]: csrfData.token },
        body: JSON.stringify({ items: body.items }), cache: "no-store", signal: AbortSignal.timeout(5000),
      });
      if (!quote.ok) return result(409, "Giỏ hàng không hợp lệ. Vui lòng tải lại giỏ.");
      const cart = (await quote.json()).data;
      if (!cart?.items?.length || !cart.items.every((item: { purchasable: boolean }) => item.purchasable)) return result(409, "Sản phẩm không còn đủ hàng. Vui lòng kiểm tra giỏ.");
    }
    const response = result(200, "Đã xác minh");
    response.cookies.set(WORKFLOW_COOKIE, signWorkflow(phase), cookieOptions);
    response.cookies.delete("checkout_allowed");
    return response;
  } catch { return result(503, "Không xác minh được luồng đặt hàng. Vui lòng thử lại."); }
}

export async function DELETE(request: NextRequest) {
  if (!sameOrigin(request)) return result(403, "Yêu cầu không hợp lệ");
  const response = result(200, "Đã kết thúc phiên đặt hàng");
  response.cookies.delete(WORKFLOW_COOKIE);
  response.cookies.delete("checkout_allowed");
  return response;
}
