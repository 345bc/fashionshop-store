"use client";

import { Suspense, useState } from "react";
import Link from "next/link";
import { useAuth } from "@/auth/AuthContext";
import { useRouter, useSearchParams } from "next/navigation";
import FieldError from "@/utils/FieldError";
import FieldSuccess from "@/utils/FieldSuccess";
import AuthNavbar from "@/components/AuthNavbar";
import styles from "@/components/PasswordRecoveryForm.module.css";

export default function RegisterPage() {
  return (
    <Suspense fallback={<p role="status">Đang tải trang đăng ký…</p>}>
      <RegisterContent />
    </Suspense>
  );
}

function RegisterContent() {
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmation, setShowConfirmation] = useState(false);
  const [confirmation, setConfirmation] = useState("");
  const [submitted, setSubmitted] = useState(false);

  const auth = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  const returnTo = searchParams?.get("returnTo");
  const loginUrl = returnTo && returnTo.startsWith("/") && !returnTo.startsWith("//") && returnTo !== "/login"
    ? `/login?returnTo=${encodeURIComponent(returnTo)}`
    : "/login";

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [username, setUsername] = useState("");
  const [fullName, setFullName] = useState("");
  const [phone, setPhone] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const handleSubmit = async (e: React.SyntheticEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);
    if (password !== confirmation) {
      setError("Mật khẩu xác nhận không khớp.");
      return;
    }
    setSubmitted(true);
    try {
      const res = await auth.register(email, password, username, fullName, phone) as { message?: string };
      setSuccess(`${res?.message || "Đăng ký thành công!"} Vui lòng đăng nhập. Đang chuyển hướng...`);
      setTimeout(() => {
        router.replace(loginUrl);
      }, 1500);
    } catch (requestError: unknown) {
      setError((requestError as Error).message || "Đăng ký thất bại");
      setSubmitted(false);
    }
  };

  const fieldClass = "grid min-w-0 gap-1 text-[15px] font-medium";
  const inputClass = "w-full min-w-0 h-11 rounded-[10px] border border-[#dbe2ec] bg-white px-3.5 font-normal shadow-xs placeholder:text-[#53657d]";
  const toggleClass = "absolute inset-y-0 right-0 grid w-11 cursor-pointer place-items-center rounded-[10px] text-[#53657d] hover:text-slate-900";
  const linkClass = "underline underline-offset-4 hover:text-slate-900";

  return (
    <div className="flex min-h-svh flex-col">
      <AuthNavbar />
      <main className={`${styles.page} ${styles.withNavbar}`}>
        <section className={`${styles.layout} ${styles.card}`} aria-labelledby="register-title">
          <h1 id="register-title">Tạo tài khoản</h1>
          <p className={styles.description}>
            Đã có tài khoản? <Link href={loginUrl} className={linkClass}>Đăng nhập</Link>
          </p>

          <FieldError error={error} className="mb-3" />
          <FieldSuccess success={success} className="mb-3" />

          <form onSubmit={handleSubmit} className="grid gap-3">
            <label className={fieldClass}>
              Email
              <input type="email" autoComplete="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="email@example.com" className={inputClass} required />
            </label>

            <label className={fieldClass}>
              Họ và tên
              <input type="text" autoComplete="name" value={fullName} onChange={e => setFullName(e.target.value)} placeholder="Nguyễn Văn A" className={inputClass} required />
            </label>

            <div className="grid gap-3 min-[420px]:grid-cols-2">
              <label className={fieldClass}>
                Tên đăng nhập
                <input type="text" autoComplete="username" value={username} onChange={e => setUsername(e.target.value)} placeholder="nguyenvana" className={inputClass} required />
              </label>
              <label className={fieldClass}>
                Số điện thoại
                <input type="tel" autoComplete="tel-national" value={phone} onChange={e => setPhone(e.target.value)} pattern="0[0-9]{9}" maxLength={10} title="Số điện thoại phải có 10 chữ số và bắt đầu bằng 0" placeholder="0123456789" className={inputClass} />
              </label>
            </div>

            <div className={fieldClass}>
              <label htmlFor="register-password">Mật khẩu</label>
              <div className="relative">
                <input id="register-password" type={showPassword ? "text" : "password"} autoComplete="new-password" value={password} onChange={e => setPassword(e.target.value)} placeholder="********" minLength={6} className={inputClass + " pr-11"} required />
                <button type="button" onClick={() => setShowPassword(value => !value)} className={toggleClass} aria-label={showPassword ? "Ẩn mật khẩu" : "Hiện mật khẩu"}>
                  <span className="material-symbols-outlined text-[19px]" aria-hidden="true">{showPassword ? "visibility" : "visibility_off"}</span>
                </button>
              </div>
            </div>

            <div className={fieldClass}>
              <label htmlFor="register-confirmation">Xác nhận mật khẩu</label>
              <div className="relative">
                <input id="register-confirmation" type={showConfirmation ? "text" : "password"} autoComplete="new-password" value={confirmation} onChange={e => setConfirmation(e.target.value)} placeholder="********" className={inputClass + " pr-11"} required />
                <button type="button" onClick={() => setShowConfirmation(value => !value)} className={toggleClass} aria-label={showConfirmation ? "Ẩn mật khẩu xác nhận" : "Hiện mật khẩu xác nhận"}>
                  <span className="material-symbols-outlined text-[19px]" aria-hidden="true">{showConfirmation ? "visibility" : "visibility_off"}</span>
                </button>
              </div>
            </div>

            <label className="flex items-start gap-2 text-sm text-[#53657d]">
              <input type="checkbox" required className="mt-1 size-4 shrink-0 cursor-pointer accent-slate-900" />
              <span>Tôi đồng ý với <Link href="/terms" className={linkClass}>điều khoản sử dụng</Link> và <Link href="/privacy" className={linkClass}>chính sách bảo mật</Link>.</span>
            </label>

            <button type="submit" disabled={submitted} className="flex min-h-11 cursor-pointer items-center justify-center gap-2 rounded-[10px] bg-slate-900 px-3 text-[15px] font-semibold text-white hover:bg-slate-800 disabled:cursor-wait disabled:opacity-70">
              <span className="material-symbols-outlined text-[19px]" aria-hidden="true">person_add</span>
              {submitted ? "Đang xử lý..." : "Tạo tài khoản"}
            </button>
          </form>
        </section>
      </main>
    </div>
  );
}
