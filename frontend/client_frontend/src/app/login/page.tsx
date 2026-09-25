"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useAuth } from "../../auth/AuthContext";
import FieldError from "@/utils/FieldError";
import FieldSuccess from "@/utils/FieldSuccess";

export default function LoginPage() {
  const auth = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  const returnTo = searchParams?.get("returnTo") ?? "/";

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

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
              <label className="remember-row"><input type="checkbox" /> <span>Ghi nhớ đăng nhập</span></label>
              <Link href="#">Quên mật khẩu?</Link>
            </div>
            <button type="submit" className="modern-submit" disabled={submitting}>
              {submitting ? "Đang đăng nhập..." : "Đăng nhập"}
            </button>
          </form>
          <div className="auth-divider"><span>hoặc</span></div>
          <button className="social-login" type="button" onClick={() => auth.loginWithMicrosoft(returnTo)}>
            G <span>Tiếp tục với Google</span>
          </button>
          <p className="auth-switch">Chưa có tài khoản? <Link href="/register">Tạo tài khoản</Link></p>
        </section>
      </main>
    </>
  );
}
