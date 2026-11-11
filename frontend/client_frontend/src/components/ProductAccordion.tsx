"use client";
import GoogleSymbol from "@/components/ui/GoogleSymbol";

import { useEffect, useId, useRef, useState } from "react";
import styles from "./ProductInformationDialog.module.css";

interface ProductAccordionProps {
  title: string;
  children: React.ReactNode;
  defaultOpen?: boolean;
}

export default function ProductAccordion({ title, children, defaultOpen = false }: ProductAccordionProps) {
  const [isOpen, setIsOpen] = useState(defaultOpen);
  const contentId = useId();
  const titleId = useId();
  const dialogRef = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    if (isOpen) {
      dialog.removeAttribute("data-closing");
      if (!dialog.open) dialog.showModal();
      return;
    }
    if (!dialog.open) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      dialog.close();
      return;
    }
    // Keep the dialog in the top layer until its exit animation finishes.
    dialog.setAttribute("data-closing", "true");
    const timeout = window.setTimeout(() => {
      dialog.close();
      dialog.removeAttribute("data-closing");
    }, 200);
    return () => window.clearTimeout(timeout);
  }, [isOpen]);

  return (
    <div className="desc-accordion-item">
      <button type="button" className="desc-accordion-header" aria-haspopup="dialog" aria-expanded={isOpen} aria-controls={contentId} onClick={() => setIsOpen(true)}>
        <span>{title}</span>
      </button>
      <dialog ref={dialogRef} id={contentId} className={styles.dialog} aria-labelledby={titleId}
        onCancel={event => { event.preventDefault(); setIsOpen(false); }} onClose={() => setIsOpen(false)}
        onClick={event => {
          if (event.target !== event.currentTarget) return;
          const bounds = event.currentTarget.getBoundingClientRect();
          if (event.clientX < bounds.left || event.clientX > bounds.right || event.clientY < bounds.top || event.clientY > bounds.bottom) setIsOpen(false);
        }}>
        <div className={styles.header}>
          <h2 id={titleId}>{title}</h2>
          <button type="button" autoFocus onClick={() => setIsOpen(false)} aria-label="Đóng thông tin sản phẩm">
            <GoogleSymbol name="close" size={18} /><span>[Đóng]</span>
          </button>
        </div>
        <div className={styles.body}><div className={styles.content}>{children}</div></div>
      </dialog>
    </div>
  );
}
