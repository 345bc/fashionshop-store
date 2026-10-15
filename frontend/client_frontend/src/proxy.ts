import { NextRequest, NextResponse } from "next/server";
import { verifyWorkflow, WORKFLOW_COOKIE } from "@/utils/server/workflowCookie";

export async function proxy(request: NextRequest) {
  const renewedCookies: string[] = [];
  const path = request.nextUrl.pathname;
  if (path === "/checkout" || path.startsWith("/checkout/") || path === "/order-success" || path.startsWith("/order-success/")) {
    const flow = verifyWorkflow(request.cookies.get(WORKFLOW_COOKIE)?.value);
    if (!flow || (path.startsWith("/order-success") && flow.phase !== "paid")) {
      return NextResponse.redirect(new URL("/products", request.url));
    }
  } else {
    const login = new URL("/login", request.url);
    login.searchParams.set("returnTo", path);
    const token = request.cookies.get("ACCESS_TOKEN")?.value;
    const refreshToken = request.cookies.get("REFRESH_TOKEN")?.value;
    if (!token && !refreshToken) return NextResponse.redirect(login);
    const backend = (process.env.BACKEND_API_BASE_URL || process.env.NEXT_PUBLIC_API_BASE_URL || `${process.env.NEXT_PUBLIC_BACKEND_URL || "http://localhost:8080"}/api/v1`).replace(/\/$/, "");
    try {
      const cookieHeader = request.cookies.getAll().map(cookie => `${cookie.name}=${encodeURIComponent(cookie.value)}`).join("; ");
      let auth = token ? await fetch(`${backend}/auth/me`, { headers: { Cookie: cookieHeader }, signal: AbortSignal.timeout(3000), cache: "no-store" }) : null;
      if ((!auth || auth.status === 401) && refreshToken) {
        const csrf = await fetch(`${backend}/auth/csrf`, { headers: { Cookie: cookieHeader }, signal: AbortSignal.timeout(3000), cache: "no-store" });
        const payload = csrf.ok ? await csrf.json() : null;
        if (!payload?.data?.headerName || !payload.data.token) return new NextResponse("Không xác minh được phiên đăng nhập. Vui lòng thử lại.", { status: 503 });
        const csrfCookies = csrf.headers.getSetCookie();
        const cookies = new Map(request.cookies.getAll().map(cookie => [cookie.name, encodeURIComponent(cookie.value)]));
        for (const cookie of csrfCookies) {
          const part = cookie.split(";", 1)[0]; const separator = part.indexOf("=");
          if (separator > 0) cookies.set(part.slice(0, separator), part.slice(separator + 1));
        }
        auth = await fetch(`${backend}/auth/refresh`, { method: "POST", headers: {
          Cookie: Array.from(cookies, ([name, value]) => `${name}=${value}`).join("; "),
          [payload.data.headerName]: payload.data.token,
        }, signal: AbortSignal.timeout(3000), cache: "no-store" });
        renewedCookies.push(...csrfCookies, ...auth.headers.getSetCookie());
      }
      if (!auth) return NextResponse.redirect(login);
      if (auth.status === 401 || auth.status === 403) {
        const response = NextResponse.redirect(login);
        response.cookies.delete("ACCESS_TOKEN");
        response.cookies.delete("REFRESH_TOKEN");
        return response;
      }
      if (!auth.ok || !(await auth.json()).data?.id) return new NextResponse("Không xác minh được phiên đăng nhập. Vui lòng thử lại.", { status: 503 });
    } catch { return new NextResponse("Không kết nối được máy chủ để xác minh phiên đăng nhập.", { status: 503 }); }
  }
  const response = NextResponse.next();
  response.headers.set("Cache-Control", "private, no-store");
  for (const cookie of renewedCookies) response.headers.append("Set-Cookie", cookie);
  return response;
}

export const config = {
  matcher: ["/checkout/:path*", "/order-success/:path*", "/profile/:path*", "/orders/:path*", "/purchase-history/:path*", "/loyalty/:path*"],
};
