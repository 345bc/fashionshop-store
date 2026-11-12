"use client";

import { useEffect, useState, type ReactNode } from "react";

export function ConnectionErrorProvider({ children }: { children: ReactNode }) {
  const [connectionFailed, setConnectionFailed] = useState(false);

  useEffect(() => {
    const report = () => setConnectionFailed(true);
    window.addEventListener("zella:connection-error", report);
    window.addEventListener("offline", report);
    if (!navigator.onLine) report();
    return () => {
      window.removeEventListener("zella:connection-error", report);
      window.removeEventListener("offline", report);
    };
  }, []);

  if (connectionFailed) {
    return <p className="m-0 px-4 pt-1" role="alert">Không thể kết nối đến máy chủ</p>;
  }

  return children;
}
