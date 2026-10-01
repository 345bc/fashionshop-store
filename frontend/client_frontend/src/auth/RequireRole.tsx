"use client";

import { ReactNode, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "./AuthContext";

export default function RequireRole({
  roles,
  children,
}: {
  roles: string[];
  children?: ReactNode;
}) {
  const auth = useAuth();
  const router = useRouter();
  const isRedirecting = useRef(false);

  const hasAccess = auth.hasRole(...roles);

  useEffect(() => {
    if (auth.status !== "loading" && auth.status !== "error" && !hasAccess && !isRedirecting.current) {
      isRedirecting.current = true;
      router.replace("/forbidden");
    }
  }, [auth.status, hasAccess, router]);

  if (auth.status === "loading") {
    return <p role="status">Đang kiểm tra quyền truy cập…</p>;
  }

  if (!hasAccess) {
    return null;
  }

  return <>{children}</>;
}
