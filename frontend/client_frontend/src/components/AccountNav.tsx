"use client";

import Link from "next/link";
import { useAuth } from "../auth/AuthContext";

export default function AccountNav({ active }: { active: "profile" | "orders" | "history" | "loyalty" }) {
  const auth = useAuth();

  const navItems = [
    { id: "profile", label: "Hồ sơ cá nhân", href: "/profile", icon: "person" },
    { id: "orders", label: "Đơn hàng của tôi", href: "/orders", icon: "local_mall" },
    { id: "history", label: "Lịch sử mua & đánh giá", href: "/purchase-history", icon: "history" },
    { id: "loyalty", label: "Điểm thưởng", href: "/loyalty", icon: "loyalty" },
  ];

  return (
    <aside className="bg-white border border-zinc-200 rounded-2xl overflow-hidden shadow-sm sticky top-24">
      {/* User Info Header */}
      <div className="p-6 border-b border-zinc-100 flex items-center gap-4 bg-zinc-50/80">
        <div className="w-12 h-12 rounded-full bg-zinc-900 text-white flex items-center justify-center font-bold text-lg shrink-0 shadow-sm">
          {(auth?.user?.profile?.fullname || "N").charAt(0).toUpperCase()}
        </div>
        <div className="flex flex-col min-w-0">
          <strong className="text-[15px] text-zinc-900 font-bold truncate">
            {auth?.user?.profile?.fullname || "Nguyễn Văn A"}
          </strong>
          <span className="text-[11px] font-bold text-zinc-500 uppercase tracking-wider mt-1">
            {/* Thành viên Bạc */}
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
                ? "bg-zinc-900 text-white shadow-md shadow-zinc-900/20"
                : "text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900"
                }`}
            >
              <span className="material-symbols-outlined text-[20px]">{item.icon}</span>
              <span className={`text-[13px] ${isActive ? "font-bold" : "font-semibold"}`}>{item.label}</span>
            </Link>
          );
        })}

        <div className="my-2 border-t border-zinc-100"></div>

        <button
          onClick={() => auth?.logout?.()}
          className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-red-600 hover:bg-red-50 hover:text-red-700 transition-colors text-left"
        >
          <span className="material-symbols-outlined text-[20px]">logout</span>
          <span className="text-[13px] font-bold">Đăng xuất</span>
        </button>
      </nav>
    </aside>
  );
}
