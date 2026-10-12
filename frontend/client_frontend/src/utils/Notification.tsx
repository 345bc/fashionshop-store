"use client";

import { useEffect, useId, useRef, useState, type ReactNode } from "react";
import styles from "./Notification.module.css";

type NotificationProps = {
  open: boolean;
  title?: string;
  message: ReactNode;
  confirmText?: string;
  cancelText?: string;
  onConfirm: () => void | Promise<void>;
  onClose: () => void;
};

export default function Notification({ open, title = "Xác nhận", message, confirmText = "Xác nhận", cancelText = "Hủy", onConfirm, onClose }: NotificationProps) {
  const dialog = useRef<HTMLDialogElement>(null);
  const cancelButton = useRef<HTMLButtonElement>(null);
  const titleId = useId();
  const messageId = useId();
  const [pending, setPending] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    const element = dialog.current;
    if (!element) return;
    if (open && !element.open) {
      element.showModal();
      cancelButton.current?.focus();
    } else if (!open && element.open) element.close();
    return () => { if (element.open) element.close(); };
  }, [open]);

  async function confirm() {
    if (pending) return;
    setPending(true); setError("");
    try { await onConfirm(); onClose(); }
    catch (cause) { setError(cause instanceof Error ? cause.message : "Không thực hiện được thao tác. Vui lòng thử lại."); }
    finally { setPending(false); }
  }

  return <dialog ref={dialog} className={styles.dialog} aria-labelledby={titleId} aria-describedby={messageId}
    onCancel={event => { event.preventDefault(); if (!pending) onClose(); }}
    onClick={event => { if (event.target === event.currentTarget && !pending) onClose(); }}>
    <div className={styles.content}>
      <h2 id={titleId} className={styles.title}>{title}</h2>
      <div id={messageId} className={styles.message}>{message}</div>
      {error && <p className={styles.error} role="alert">{error}</p>}
      <div className={styles.actions}>
        <button ref={cancelButton} type="button" className={styles.cancel} disabled={pending} onClick={onClose}>{cancelText}</button>
        <button type="button" className={styles.confirm} disabled={pending} onClick={() => void confirm()}>{pending ? "Đang xử lý..." : confirmText}</button>
      </div>
    </div>
  </dialog>;
}
