"use client";

import { Suspense, useState, useEffect } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useAuth, takeLoginReturnTo } from "../../auth/AuthContext";
import FieldError from "@/utils/FieldError";
import FieldSuccess from "@/utils/FieldSuccess";

export default function LoginPage() {
  return (
    <Suspense fallback={<p role="status">Đang tải trang đăng nhập…</p>}>
      <LoginContent />
    </Suspense>
  );
}

function LoginContent() {
  const auth = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  const requestedReturn = searchParams?.get("returnTo") ?? "/";
  const returnTo = !requestedReturn.includes("\\") && /^\/(profile|orders|purchase-history|loyalty|checkout|products)(\/|\?|$)/.test(requestedReturn) ? requestedReturn : "/";

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [remember, setRemember] = useState(false);

  useEffect(() => {
    const oauthStatus = searchParams?.get("oauth2");
    const oauthError = searchParams?.get("error");
    if (oauthStatus === "success") {
      auth.refresh().then(() => {
        setSuccess("Đăng nhập Google thành công! Đang chuyển hướng...");
        const dest = takeLoginReturnTo();
        setTimeout(() => {
          router.push(dest);
        }, 800);
      }).catch(() => {
        setError("Không thể đồng bộ phiên đăng nhập Google");
      });
    } else if (oauthError) {
      queueMicrotask(() => {
        if (oauthError === "email_missing") {
          setError("Tài khoản Google của bạn không cung cấp địa chỉ email");
        } else {
          setError("Đăng nhập bằng Google không thành công. Vui lòng thử lại");
        }
      });
    }
  }, [searchParams, auth, router]);

  const handleSubmit = async (e: React.SyntheticEvent<HTMLFormElement>) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      const res = await auth.login(email, password) as { message?: string };
      setSuccess(res?.message || "Đăng nhập thành công! Đang chuyển hướng...");
      setTimeout(() => {
        router.push(returnTo);
      }, 1500);
    } catch (requestError: unknown) {
      setError((requestError as Error).message || "Đăng nhập thất bại");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <>
      <FieldError error={error} className="mb-4" />
      <FieldSuccess success={success}></FieldSuccess>
      <header className="sticky top-0 z-50 flex items-center justify-center border-b border-black/10  h-16 lg:h-18">
        <Link
          href="/"
          className="whitespace-nowrap text-[18px] font-bold tracking-[0.2em] text-[#1d211c] lg:text-[22px]"
          aria-label="Zella  "
        >
          ZELLA<span className="ml-1.5 align-middle text-[9px] font-medium tracking-[0.14em] text-[#777a72] lg:inline"></span>
        </Link>
      </header>
      <main className="auth-page-modern">
        <section className="auth-card-modern">
          <div className="auth-card-head">
            <h1>Đăng nhập</h1>
          </div>
          <form className="modern-form" onSubmit={handleSubmit}>
            <label>
              <span>Email</span>
              <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@example.com" required />
            </label>
            <label>
              <span>Mật khẩu</span>
              <div className="password-field">
                <input type={showPassword ? "text" : "password"} value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Nhập mật khẩu" required />
                <button type="button" onClick={() => setShowPassword((v) => !v)} aria-label="Hiện hoặc ẩn mật khẩu">
                  <span className="material-symbols-outlined" style={{ fontSize: 18 }}>
                    {showPassword ? "visibility_off" : "visibility"}
                  </span>
                </button>
              </div>
            </label>
            <div className="form-row-between">
              <label className="remember-row"><input type="checkbox" checked={remember} onChange={(e) => setRemember(e.target.checked)} /> <span>Ghi nhớ đăng nhập</span></label>
              <Link href="/forgot-password">Quên mật khẩu?</Link>
            </div>
            <button type="submit" className="modern-submit" disabled={submitting}>
              {submitting ? "Đang đăng nhập..." : "Đăng nhập"}
            </button>
          </form>
          <div className="auth-divider"><span>hoặc</span></div>
          <button className="social-login flex items-center justify-center gap-2" type="button" onClick={() => auth.loginWithGoogle(returnTo)}>
            <svg width="18" height="18" viewBox="0 0 24 24" style={{ display: "inline-block", verticalAlign: "middle" }}>
              <path fill="#4285F4" d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.8-2.4 3.66v3.04h3.88c2.28-2.09 3.6-5.17 3.6-9.14z"/>
              <path fill="#34A853" d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.04c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.25v3.13C3.26 21.36 7.36 24 12 24z"/>
              <path fill="#FBBC05" d="M5.28 14.28c-.25-.72-.38-1.49-.38-2.28s.13-1.56.38-2.28V6.59H1.25C.45 8.18 0 9.99 0 12s.45 3.82 1.25 5.41l4.03-3.13z"/>
              <path fill="#EA4335" d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.36 0 3.26 2.64 1.25 6.59l4.03 3.13c.95-2.83 3.6-4.97 6.72-4.97z"/>
            </svg>
            <span>Tiếp tục với Google</span>
          </button>
          <p className="auth-switch">Chưa có tài khoản? <Link href="/register">Tạo tài khoản</Link></p>
        </section>
      </main>
    </>
  );
}
