import { useState, useEffect } from "react";

interface FieldSuccessProps {
  success?: string | null;
  className?: string;
}

export default function FieldSuccess({ success, className = "" }: FieldSuccessProps) {
  const [visible, setVisible] = useState(!!success);
  const [prevSuccess, setPrevSuccess] = useState(success);

  if (success !== prevSuccess) {
    setPrevSuccess(success);
    setVisible(!!success);
  }

  useEffect(() => {
    if (success && visible) {
      const timer = setTimeout(() => {
        setVisible(false);
      }, 5000);
      return () => clearTimeout(timer);
    }
  }, [success, visible]);

  if (!success || !visible) return null;

  return (
    <div
      className={`fixed top-20 right-5 z-9999 flex w-full max-w-75 items-start gap-3 rounded-md bg-white p-4 shadow-[0_4px_24px_rgba(0,0,0,0.06)] border border-black/5 animate-in slide-in-from-right-8 fade-in duration-300 ease-out ${className}`}
      role="alert"
    >
      <span className="material-symbols-outlined shrink-0 text-[#1d211c]" style={{ fontSize: 18 }} aria-hidden="true">
        check_circle
      </span>
      <span className="mt-0.5 text-[13px] font-medium leading-relaxed text-[#1d211c]">{success}</span>
    </div>
  );
}
