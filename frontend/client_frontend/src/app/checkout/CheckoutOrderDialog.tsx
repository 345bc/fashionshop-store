"use client";
import GoogleSymbol from "@/components/ui/GoogleSymbol";


import { useEffect, useId, useRef, type ReactNode } from "react";
import styles from "./CheckoutOrderDialog.module.css";

export default function CheckoutOrderDialog({ open, title, busy = false, onClose, children }: {
  open: boolean; title: string; busy?: boolean; onClose: () => void; children: ReactNode;
}) {
  const dialog = useRef<HTMLDialogElement>(null);
  const titleId = useId();
  useEffect(() => {
    const element = dialog.current;
    if (!element) return;
    if (open && !element.open) element.showModal();
    else if (!open && element.open) element.close();
    return () => { if (element.open) element.close(); };
  }, [open]);

  return <dialog ref={dialog} className={styles.dialog} aria-labelledby={titleId}
    onCancel={event => { event.preventDefault(); if (!busy) onClose(); }}
    onClick={event => {
      if (event.target !== event.currentTarget || busy) return;
      const rect = event.currentTarget.getBoundingClientRect();
      if (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom) onClose();
    }}>
    <header className={styles.header}>
      <h2 id={titleId}>{title}</h2>
      <button type="button" autoFocus aria-label="Đóng hộp thoại" disabled={busy} onClick={onClose} className={styles.close}>
        <GoogleSymbol name="close" size={20} />
      </button>
    </header>
    <div className={styles.content}>{children}</div>
  </dialog>;
}
