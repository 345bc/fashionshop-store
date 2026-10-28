"use client";

import Link from "next/link";
import { createContext, useCallback, useContext, useEffect, useId, useMemo, useRef, useState, type ReactNode } from "react";
import styles from "./ConnectionError.module.css";

type Failure = { onRetry: () => void; message?: string };
const ConnectionErrors = createContext<((id: string, failure: Failure) => () => void) | null>(null);

export function ConnectionErrorProvider({ children }: { children: ReactNode }) {
  const [failures, setFailures] = useState<Map<string, Failure>>(new Map());
  const dialog = useRef<HTMLDialogElement>(null);
  const register = useCallback((id: string, failure: Failure) => {
    setFailures(current => new Map(current).set(id, failure));
    return () => setFailures(current => {
      const next = new Map(current);
      next.delete(id);
      return next;
    });
  }, []);
  useEffect(() => {
    const report = () => setFailures(current => new Map(current).set("global", { onRetry: () => window.location.reload() }));
    window.addEventListener("zella:connection-error", report);
    window.addEventListener("offline", report);
    if (!navigator.onLine) report();
    return () => {
      window.removeEventListener("zella:connection-error", report);
      window.removeEventListener("offline", report);
    };
  }, []);
  const active = failures.size > 0;
  useEffect(() => {
    if (!active) return;
    const element = dialog.current;
    element?.showModal();
    const previousBodyOverflow = document.body.style.overflow;
    const previousHtmlOverflow = document.documentElement.style.overflow;
    document.body.style.overflow = "hidden";
    document.documentElement.style.overflow = "hidden";
    return () => {
      element?.close();
      document.body.style.overflow = previousBodyOverflow;
      document.documentElement.style.overflow = previousHtmlOverflow;
    };
  }, [active]);
  const failure = useMemo(() => failures.values().next().value, [failures]);
  return <ConnectionErrors.Provider value={register}>
    {children}
    {active && <dialog ref={dialog} className={styles.overlay} aria-label="Không thể kết nối đến máy chủ" onCancel={event => event.preventDefault()}>
      <ErrorContent message={failure?.message} onRetry={() => {
        if (failures.has("global")) { window.location.reload(); return; }
        const retryAll = [...failures.values()];
        setFailures(new Map());
        retryAll.forEach(item => item.onRetry());
      }} />
    </dialog>}
  </ConnectionErrors.Provider>;
}

export default function ConnectionError({ onRetry, fullPage = false, message }: {
  onRetry: () => void; fullPage?: boolean; message?: string;
}) {
  const register = useContext(ConnectionErrors);
  const id = useId();
  useEffect(() => {
    if (fullPage || !register) return;
    return register(id, { onRetry, message });
  }, [register, id, onRetry, message, fullPage]);
  if (!fullPage && register) return null;
  return <ErrorContent onRetry={onRetry} fullPage={fullPage} message={message} />;
}

function ErrorContent({ onRetry, fullPage = false, message }: Failure & { fullPage?: boolean }) {
  return <section className={`${styles.state} ${fullPage ? styles.fullPage : ""}`} role="alert">
    <div className={styles.icon} aria-hidden="true">
      <svg viewBox="0 0 64 64" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
        <path d="M12 24a31 31 0 0 1 40 0M20 33a19 19 0 0 1 24 0M28 42a7 7 0 0 1 8 0M13 12l38 40" />
        <circle cx="32" cy="51" r="1.5" fill="currentColor" stroke="none" />
      </svg>
    </div>
    <p className={styles.eyebrow}>OOPS!</p>
    <h2>Không thể kết nối đến máy chủ</h2>
    <p className={styles.description}>{message ?? "Kết nối đang bị gián đoạn. Bạn kiểm tra mạng và thử lại sau một chút nhé."}</p>
    <div className={styles.actions}>
      <button type="button" onClick={onRetry}>Thử lại <span aria-hidden="true">↻</span></button>
      {fullPage && <Link href="/">Về trang chủ <span aria-hidden="true">↗</span></Link>}
    </div>
  </section>;
}
