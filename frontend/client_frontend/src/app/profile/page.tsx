"use client";

import { useCallback, useState, useEffect } from "react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import AccountNav from "@/components/AccountNav";

import { useAuth } from "@/auth/AuthContext";
import { getIdByUserId } from "./api/customerApi";

export default function ProfilePage() {
  const [saved, setSaved] = useState(false);
  const auth = useAuth();

  const [profileState, setProfileState] = useState<{ status: string; data: Record<string, unknown> | null; error: unknown }>({
    status: "idle",
    data: null,
    error: null,
  });

  const load = useCallback(async () => {
    if (!auth?.user?.id) return;
    try {
      setProfileState((current) => ({ ...current, status: "loading" }));
      const response = await getIdByUserId(auth.user.id as string);
      setProfileState({ status: "success", data: response.data, error: null });
    } catch (error) {
      setProfileState((current) => ({ ...current, status: "error", error }));
    }
  }, [auth?.user?.id]);

  useEffect(() => {
    load();
  }, [load]);




  return (
    <>
      <Header />
      <main className="container mx-auto px-4 sm:px-8 py-10 md:py-16">
        <div className="flex flex-col md:flex-row gap-10 lg:gap-16">

          {/* Sidebar */}
          <div className="w-full md:w-65 lg:w-70 shrink-0">
            <AccountNav active="profile" />
          </div>

          {/* Main Content */}
          <section className="flex-1 max-w-3xl">
            <div className="mb-10">
              <span className="text-[11px] font-bold tracking-[0.15em] text-zinc-500 uppercase mb-3 block">My Account</span>
              <h1 className="text-3xl md:text-4xl font-bold tracking-tight text-zinc-900 mb-3">Hồ sơ cá nhân</h1>
            </div>

            <form
              onSubmit={(e) => {
                e.preventDefault();
                setSaved(true);
                setTimeout(() => setSaved(false), 2500);
              }}
            >
              {/* Thông tin cơ bản */}
              <div className="bg-white border border-zinc-200 rounded-2xl overflow-hidden shadow-sm mb-8 transition-shadow hover:shadow-md">
                <div className="px-6 md:px-8 py-5 border-b border-zinc-100 flex items-center justify-between bg-zinc-50/80">
                  <div>
                    <h2 className="text-[17px] font-bold text-zinc-900">Thông tin cơ bản</h2>
                    <p className="text-[13px] text-zinc-500 mt-0.5">Email dùng để đăng nhập sẽ không thể thay đổi tại đây.</p>
                  </div>
                  {saved && (
                    <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-green-100 text-green-700 text-[12px] font-bold tracking-wide animate-in fade-in zoom-in duration-300">
                      <span className="material-symbols-outlined text-[16px]">check_circle</span> ĐÃ LƯU
                    </span>
                  )}
                </div>

                <div className="px-6 md:px-8 py-8 grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-7">
                  <div className="flex flex-col gap-2">
                    <label className="text-[13px] font-bold text-zinc-700">Họ và tên</label>
                    <input
                      className="h-12 px-4 rounded-xl border border-zinc-300 bg-white text-[14px] text-zinc-900 font-medium focus:outline-none focus:border-black focus:ring-1 focus:ring-black transition-colors"
                      defaultValue={(profileState.data?.fullName as string) || (auth?.user?.profile?.fullname as string) || ""}
                      placeholder="Nhập họ và tên..."
                    />
                  </div>

                  <div className="flex flex-col gap-2">
                    <label className="text-[13px] font-bold text-zinc-700">Số điện thoại</label>
                    <input
                      className="h-12 px-4 rounded-xl border border-zinc-300 bg-white text-[14px] text-zinc-900 font-medium focus:outline-none focus:border-black focus:ring-1 focus:ring-black transition-colors"
                      defaultValue={(profileState.data?.phone as string) || (auth?.user?.profile?.phone as string) || ""}
                      placeholder="Chưa cập nhật"
                    />
                  </div>

                  <div className="flex flex-col gap-2 md:col-span-2">
                    <label className="text-[13px] font-bold text-zinc-700">Email</label>
                    <input
                      className="h-12 px-4 rounded-xl border border-zinc-200 bg-zinc-50 text-[14px] text-zinc-400 font-medium cursor-not-allowed focus:outline-none"
                      defaultValue={(profileState.data?.email as string) || (auth?.user?.email as string) || ""}
                      readOnly
                    />
                  </div>
                </div>
              </div>

              {/* Địa chỉ mặc định */}
              <div className="bg-white border border-zinc-200 rounded-2xl overflow-hidden shadow-sm mb-10 transition-shadow hover:shadow-md">
                <div className="px-6 md:px-8 py-5 border-b border-zinc-100 bg-zinc-50/80">
                  <h2 className="text-[17px] font-bold text-zinc-900">Địa chỉ mặc định</h2>
                  <p className="text-[13px] text-zinc-500 mt-0.5">Được tự động điền khi bạn thanh toán.</p>
                </div>

                <div className="px-6 md:px-8 py-8">
                  <div className="flex flex-col gap-2">
                    <label className="text-[13px] font-bold text-zinc-700">Địa chỉ cụ thể</label>
                    <input
                      type="text"
                      className="h-12 px-4 rounded-xl border border-zinc-300 bg-white text-[14px] text-zinc-900 font-medium focus:outline-none focus:border-black focus:ring-1 focus:ring-black transition-colors"
                      defaultValue={(profileState.data?.address as string) || (auth?.user?.profile?.address as string) || ""}
                      placeholder="Chưa có địa chỉ..."
                    />
                  </div>
                </div>
              </div>

              {/* Nút Submit */}
              <div className="flex justify-end">
                <button
                  className="h-13 px-10 bg-zinc-900 text-white rounded-full text-[13px] font-bold tracking-wider uppercase hover:bg-black hover:shadow-lg hover:shadow-black/20 transition-all duration-300 active:scale-95"
                  type="submit"
                >
                  Lưu thay đổi
                </button>
              </div>
            </form>
          </section>
        </div>
      </main>
      <Footer />
    </>
  );
}
