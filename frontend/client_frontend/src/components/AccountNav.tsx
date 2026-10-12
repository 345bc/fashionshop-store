"use client";

import Link from "next/link";
import { useAuth } from "../auth/AuthContext";
import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { getIdByUserId } from "@/service/customerApi";

export default function AccountNav({ active }: { active: "profile" | "orders" | "loyalty" }) {
  const auth = useAuth();
  const router = useRouter();
  const [loggingOut, setLoggingOut] = useState(false);
  const [logoutError, setLogoutError] = useState("");

  const handleLogout = async () => {
    setLoggingOut(true);
    setLogoutError("");
    try {
      await auth.logout();
      router.push("/");
    } catch {
      setLogoutError("Chưa thể đăng xuất. Vui lòng thử lại.");
    } finally {
      setLoggingOut(false);
    }
  };

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

  const navItems = [
    { id: "profile", label: "Hồ sơ cá nhân", href: "/profile", icon: "person" },
    { id: "orders", label: "Đơn hàng của tôi", href: "/orders", icon: "local_mall" },
    { id: "loyalty", label: "Điểm thưởng", href: "/loyalty", icon: "loyalty" },
  ];

  return (
    <aside className="bg-white border border-zinc-200 rounded-2xl overflow-hidden shadow-sm sticky top-24">
      {/* User Info Header */}
      <div className="p-6 border-b border-zinc-100 flex items-center gap-4 bg-zinc-50/80">
        <div className="w-12 h-12 rounded-full bg-zinc-900 text-white flex items-center justify-center font-bold text-lg shrink-0 shadow-sm">
          {((profileState?.data?.fullName) as string || "N").charAt(0).toUpperCase()}
        </div>
        <div className="flex flex-col min-w-0">
          <strong className="text-[15px] text-zinc-900 font-bold truncate">
            {(profileState?.data?.fullName) as string || ""}
          </strong>
          <span className="text-[11px] font-bold text-zinc-500 uppercase tracking-wider mt-1">
            {(profileState?.data?.membershipTier) as string || ""}
          </span>
        </div>
      </div>

      {/* Navigation */}
      <nav className="p-3 flex flex-col gap-1">
        {navItems.map((item) => {
          const isActive = active === item.id;
          return (
            <Link
              key={item.id}
              href={item.href}
              className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-300 ${isActive
                ? "bg-zinc-800 text-white shadow-md shadow-zinc-900/20"
                : "text-xl hover:bg-zinc-100 "
                }`}
            >
              <span className="material-symbols-outlined text-[20px]">{item.icon}</span>
              <span className={`text-[14px]  "font-normal"`}>{item.label}</span>
            </Link>
          );
        })}

        <div className="my-2 border-t border-zinc-100"></div>

        <button
          type="button"
          onClick={handleLogout}
          disabled={loggingOut}
          className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-red-600 hover:bg-red-50 hover:text-red-700 transition-colors text-left"
        >
          <span className="material-symbols-outlined text-[20px]">logout</span>
          <span className="text-[13px] font-bold">{loggingOut ? "Đang đăng xuất…" : "Đăng xuất"}</span>
        </button>
        {logoutError && <p role="alert" className="px-4 text-xs text-red-600">{logoutError}</p>}
      </nav>
    </aside>
  );
}
