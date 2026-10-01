"use client";
import { useState, useEffect } from "react"; interface FieldErrorProps {
  error?: string | null;
  className?: string;
}

export default function FieldError({ error, className = "" }: FieldErrorProps) {
  const [visible, setVisible] = useState(!!error);
  const [prevError, setPrevError] = useState(error);

  if (error !== prevError) {
    setPrevError(error);
    setVisible(!!error);
  }

  useEffect(() => {
    if (error && visible) {
      const timer = setTimeout(() => {
        setVisible(false);
      }, 5000);
      return () => clearTimeout(timer);
    }
  }, [error, visible]);

  if (!error || !visible) return null;
  return (
    <div
      className={`fixed top-20 right-5 z-9999 flex w-full max-w-75 items-start gap-3 rounded-md bg-white p-4 shadow-[0_4px_24px_rgba(0,0,0,0.06)] border border-black/5 animate-in slide-in-from-right-8 fade-in duration-300 ease-out ${className}`}
      role="alert"
    >
      <span className="material-symbols-outlined shrink-0 text-red-500" style={{ fontSize: 18 }} aria-hidden="true">
        error
      </span>
      <span className="mt-0.5 text-[13px] font-medium leading-relaxed text-[#1d211c]">{error}</span>
    </div>
  );
}
