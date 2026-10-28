"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { apiRequest } from "@/api/apiClient";

export default function PasswordRecoveryForm({ reset = false }: { reset?: boolean }) {
  const [email, setEmail] = useState("");
  const [token, setToken] = useState("");
  const [password, setPassword] = useState("");
  const [confirmation, setConfirmation] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  useEffect(() => {
    if (!reset) return;
    const frame = window.requestAnimationFrame(() => {
      const value = new URLSearchParams(window.location.hash.slice(1)).get("token") || "";
      setToken(value);
      window.history.replaceState(null, "", window.location.pathname);
      if (!/^[A-Za-z0-9_-]{43}$/.test(value)) setError("Liên kết không hợp lệ. Vui lòng yêu cầu liên kết mới.");
    });
    return () => window.cancelAnimationFrame(frame);
  }, [reset]);

  async function submit(event: React.SyntheticEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    if (reset && password !== confirmation) { setError("Mật khẩu xác nhận không khớp."); return; }
    if (reset && new TextEncoder().encode(password).length > 72) { setError("Mật khẩu không được vượt quá 72 byte UTF-8."); return; }
    setBusy(true);
    try {
      const result = await apiRequest(reset ? "/auth/reset-password" : "/auth/forgot-password", {
        method: "POST", body: reset ? { token, password } : { email: email.trim() },
      });
      setSuccess(result.message);
      setPassword(""); setConfirmation("");
    } catch (failure) {
      setError(failure instanceof Error ? failure.message : "Không thể xử lý yêu cầu. Vui lòng thử lại.");
    } finally { setBusy(false); }
  }

  return (
    <main className="auth-page-modern">
      <section className="auth-card-modern">
        <div className="auth-card-head">
          <Link href="/" aria-label="Trang chủ ZELLA">ZELLA</Link>
          <h1>{reset ? "Đặt lại mật khẩu" : "Quên mật khẩu"}</h1>
          <p>{reset ? "Nhập mật khẩu mới có ít nhất 8 ký tự." : "Nhập email đã đăng ký để nhận liên kết đặt lại mật khẩu."}</p>
        </div>
        {error && <p role="alert" className="text-red-700 mb-4">{error}</p>}
        {success ? <p role="status" className="mb-4">{success}</p> : (
          <form className="modern-form" onSubmit={submit}>
            {reset ? <>
              <label><span>Mật khẩu mới</span><input type="password" autoComplete="new-password" minLength={8} maxLength={72} required value={password} onChange={e => setPassword(e.target.value)} /></label>
              <label><span>Xác nhận mật khẩu</span><input type="password" autoComplete="new-password" minLength={8} maxLength={72} required value={confirmation} onChange={e => setConfirmation(e.target.value)} /></label>
            </> : <label><span>Email</span><input type="email" autoComplete="email" maxLength={100} required value={email} onChange={e => setEmail(e.target.value)} placeholder="you@gmail.com" /></label>}
            <button className="modern-submit" type="submit" disabled={busy || (reset && !/^[A-Za-z0-9_-]{43}$/.test(token))}>
              {busy ? "Đang xử lý..." : reset ? "Lưu mật khẩu mới" : "Gửi liên kết"}
            </button>
          </form>
        )}
        <p className="auth-switch"><Link href="/login">Quay lại đăng nhập</Link></p>
        {reset && <p className="auth-switch"><Link href="/forgot-password">Yêu cầu liên kết mới</Link></p>}
      </section>
    </main>
  );
}
