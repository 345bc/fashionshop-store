"use client";

import { ReactNode, useEffect, useRef } from "react";
import { useRouter, usePathname, useSearchParams } from "next/navigation";
import { useAuth } from "./AuthContext";

export default function RequireAuth({ children }: { children: ReactNode }) {
  const auth = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const isRedirecting = useRef(false);

  useEffect(() => {
    if (auth.status !== "loading" && auth.status !== "error" && !auth.user && !isRedirecting.current) {
      isRedirecting.current = true;
      const searchStr = searchParams ? `?${searchParams.toString()}` : "";
      const from = `${pathname}${searchStr}`;
      router.replace(`/login?returnTo=${encodeURIComponent(from)}`);
    }
  }, [auth.status, auth.user, pathname, searchParams, router]);

  if (auth.status === "loading") {
    return <p role="status">Đang kiểm tra phiên đăng nhập…</p>;
  }

  if (auth.status === "error") {
    return (
      <div className="status-card error" role="alert">
        <div>
          <strong>Không thể kiểm tra phiên đăng nhập</strong>
          <p>{(auth.error as Error)?.message || String(auth.error)}</p>
          <button
            className="button secondary"
            type="button"
            onClick={() => auth.refresh().catch(() => { })}
          >
            Thử lại
          </button>
        </div>
      </div>
    );
  }

  if (!auth.user) {
    return null; // Will redirect in useEffect
  }

  if (!auth.user.activeRole && auth.user.roles && auth.user.roles.length > 0) {
    return (
      <div style={{ padding: "20px" }}>
        <p>Đang chờ chọn vai trò...</p>
        {/* <SelectRoleModal /> */}
      </div>
    );
  }

  return <>{children}</>;
}
