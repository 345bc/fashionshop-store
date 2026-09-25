"use client";

import { useState } from "react";
import Link from "next/link";
import { useAuth } from "@/auth/AuthContext";
import { useRouter, useSearchParams } from "next/navigation";
import FieldError from "@/utils/FieldError";
import FieldSuccess from "@/utils/FieldSuccess";

export default function RegisterPage() {
  const [showPassword, setShowPassword] = useState(false);
  const [submitted, setSubmitted] = useState(false);

  const auth = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  const returnTo = searchParams?.get("returnTo") ?? "/login";

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [username, setUsername] = useState("");
  const [fullName, setFullName] = useState("");
  const [phone, setPhone] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const handleSubmit = async (e: React.SyntheticEvent<HTMLFormElement>) => {
    e.preventDefault();
    setSubmitted(true);
    setError(null);
    try {
      const res = await auth.register(email, password, username, fullName, phone) as { message?: string };
      setSuccess(res?.message || "Đăng ký thành công! Đang chuyển hướng...");
      setTimeout(() => {
        router.push(returnTo);
      }, 1500);
    } catch (requestError: unknown) {
      setError((requestError as Error).message || "Đăng ký thất bại");
    } finally {
      if (!success) {
        setSubmitted(false);
      }
    }
  };

  return (
    <>
      <header className="sticky top-0 z-50 flex items-center justify-center border-b border-zinc-200 bg-white h-16 lg:h-18">
        <Link
          href="/"
          className="whitespace-nowrap text-[20px] font-bold tracking-[0.2em] text-zinc-900"
          aria-label="Zella Studio - Trang chủ"
        >
          ZELLA
        </Link>
      </header>

      <main className="min-h-[calc(100vh-72px)] bg-zinc-50 flex flex-col items-center justify-center p-4 py-10">
        <div className="w-full max-w-md bg-white rounded-2xl shadow-sm border border-zinc-200 overflow-hidden">
          <div className="px-6 py-8 sm:p-8">
            <div className="text-center mb-8">
              <h1 className="text-2xl font-bold text-zinc-900 tracking-tight">Tạo tài khoản</h1>
              <p className="text-[13.5px] text-zinc-500 mt-2">Điền thông tin bên dưới để tham gia cùng Zella Studio.</p>
            </div>

            <FieldError error={error} className="mb-5" />
            <FieldSuccess success={success} className="mb-5" />

            <form onSubmit={handleSubmit} className="flex flex-col gap-4.5">
              {/* Họ và tên */}
              <div className="flex flex-col gap-1.5">
                <label className="text-[13px] font-bold text-zinc-700">Họ và tên</label>
                <input
                  type="text"
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  placeholder="Nguyễn Văn A"
                  className="h-11 px-4 rounded-xl border border-zinc-300 bg-white text-[14px] text-zinc-900 font-medium focus:outline-none focus:border-black focus:ring-1 focus:ring-black transition-colors placeholder:text-zinc-400"
                  required
                />
              </div>

              {/* Tên đăng nhập & Số điện thoại (Chia 2 cột) */}
              <div className="grid grid-cols-2 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="text-[13px] font-bold text-zinc-700">Tên đăng nhập</label>
                  <input
                    type="text"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    placeholder="nguyenvana"
                    className="h-11 px-4 rounded-xl border border-zinc-300 bg-white text-[14px] text-zinc-900 font-medium focus:outline-none focus:border-black focus:ring-1 focus:ring-black transition-colors placeholder:text-zinc-400"
                    required
                  />
                </div>
                <div className="flex flex-col gap-1.5">
                  <label className="text-[13px] font-bold text-zinc-700">Số điện thoại</label>
                  <input
                    type="tel"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="0912345678"
                    className="h-11 px-4 rounded-xl border border-zinc-300 bg-white text-[14px] text-zinc-900 font-medium focus:outline-none focus:border-black focus:ring-1 focus:ring-black transition-colors placeholder:text-zinc-400"
                  />
                </div>
              </div>

              {/* Email */}
              <div className="flex flex-col gap-1.5">
                <label className="text-[13px] font-bold text-zinc-700">Email</label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="you@example.com"
                  className="h-11 px-4 rounded-xl border border-zinc-300 bg-white text-[14px] text-zinc-900 font-medium focus:outline-none focus:border-black focus:ring-1 focus:ring-black transition-colors placeholder:text-zinc-400"
                  required
                />
              </div>

              {/* Mật khẩu */}
              <div className="flex flex-col gap-1.5">
                <label className="text-[13px] font-bold text-zinc-700">Mật khẩu</label>
                <div className="relative">
                  <input
                    type={showPassword ? "text" : "password"}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Tối thiểu 6 ký tự"
                    minLength={6}
                    className="w-full h-11 px-4 pr-11 rounded-xl border border-zinc-300 bg-white text-[14px] text-zinc-900 font-medium focus:outline-none focus:border-black focus:ring-1 focus:ring-black transition-colors placeholder:text-zinc-400"
                    required
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-zinc-400 hover:text-zinc-700 transition-colors"
                  >
                    <span className="material-symbols-outlined" style={{ fontSize: 20 }}>
                      {showPassword ? "visibility_off" : "visibility"}
                    </span>
                  </button>
                </div>
              </div>

              {/* Điều khoản */}
              <label className="flex items-start gap-3 mt-1 cursor-pointer group">
                <div className="relative flex items-center justify-center shrink-0 mt-0.5">
                  <input type="checkbox" required className="w-4 h-4 rounded border-zinc-300 text-zinc-900 focus:ring-black cursor-pointer peer appearance-none checked:bg-zinc-900 checked:border-zinc-900 transition-all" />
                  <span className="material-symbols-outlined absolute text-white pointer-events-none opacity-0 peer-checked:opacity-100" style={{ fontSize: 14 }}>check</span>
                </div>
                <span className="text-[13px] text-zinc-500 font-medium leading-snug group-hover:text-zinc-700 transition-colors">
                  Tôi đồng ý với <Link href="/terms" className="text-zinc-900 font-bold hover:underline">điều khoản sử dụng</Link> và <Link href="/privacy" className="text-zinc-900 font-bold hover:underline">chính sách bảo mật</Link>.
                </span>
              </label>

              {/* Nút Đăng ký */}
              <button
                type="submit"
                disabled={submitted}
                className="h-12 w-full mt-3 bg-zinc-900 text-white rounded-xl text-[13px] font-bold tracking-wider uppercase hover:bg-black hover:shadow-lg hover:shadow-black/20 transition-all duration-300 active:scale-[0.98] disabled:opacity-70 disabled:pointer-events-none"
              >
                {submitted ? "Đang xử lý..." : "Tạo tài khoản"}
              </button>
            </form>

            {/* Chuyển trang đăng nhập */}
            {!submitted && (
              <p className="mt-8 text-center text-[13.5px] text-zinc-500 font-medium">
                Đã có tài khoản? <Link href="/login" className="text-zinc-900 font-bold hover:underline ml-1">Đăng nhập ngay</Link>
              </p>
            )}
          </div>
        </div>
      </main>
    </>
  );
}
