"use client";
import GoogleSymbol from "@/components/ui/GoogleSymbol";

import { useEffect, useId, useRef, type ReactNode } from "react";

export default function AccountDialog({ title, children, onClose, busy = false }: { title: string; children: ReactNode; onClose: () => void; busy?: boolean }) {
  const ref = useRef<HTMLDialogElement>(null);
  const titleId = useId();
  useEffect(() => { const dialog = ref.current; dialog?.showModal(); return () => dialog?.close(); }, []);
  return <dialog ref={ref} aria-labelledby={titleId} className="m-auto w-[calc(100%-2rem)] max-w-2xl max-h-[85vh] overflow-auto rounded-xl border border-gray-200 p-6 backdrop:bg-black/40"
    onCancel={event => { event.preventDefault(); if (!busy) onClose(); }}>
    <div className="flex justify-between items-center gap-4 mb-6"><h2 id={titleId} className="text-lg font-bold">{title}</h2>
      <button type="button" aria-label="Đóng" disabled={busy} onClick={onClose} className="size-9 border rounded-full"><GoogleSymbol name="close" size={20} /></button></div>{children}
  </dialog>;
}
