"use client";

import Link from "next/link";
import styles from "./account/AccountLayout.module.css";
import { useAuth } from "../auth/AuthContext";
import { useCallback, useEffect, useState } from "react";
import { getIdByUserId } from "@/service/customerApi";

export default function AccountNav({ active }: { active: "profile" | "orders" | "loyalty" }) {
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

  const navItems = [
    { id: "profile", label: "Hồ sơ cá nhân", href: "/profile" },
    { id: "orders", label: "Đơn hàng của tôi", href: "/orders" },
    { id: "loyalty", label: "Điểm thưởng", href: "/loyalty" },
  ];

  const fullName = String(profileState.data?.fullName || auth.user?.profile?.fullname || auth.user?.username || 'Tài khoản');
  const email = String(profileState.data?.email || auth.user?.email || '');

  return (
    <aside className={styles.sidebar}>
      <div className={styles.identity}>
        <p className={styles.eyebrow}>Tài khoản</p>
        <h2>{fullName}</h2>
        {email && <p className={styles.email}>{email}</p>}
      </div>
      <nav className={styles.navigation} aria-label="Điều hướng tài khoản">
        {navItems.map(item => <Link key={item.id} href={item.href}
          aria-current={active === item.id ? 'page' : undefined}
          className={active === item.id ? styles.active : undefined}>
          {item.label}
        </Link>)}

      </nav>
    </aside>
  );
}
