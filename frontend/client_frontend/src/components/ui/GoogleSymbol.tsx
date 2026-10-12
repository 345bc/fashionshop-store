import type { CSSProperties } from "react";

export default function GoogleSymbol({ name, size = 20, filled = false, className = "" }: {
  name: string; size?: number; filled?: boolean; className?: string;
}) {
  return <span aria-hidden="true" className={`material-symbols-outlined ${className}`} style={{
    fontSize: size,
    "--symbol-fill": filled ? 1 : 0,
  } as CSSProperties}>{name}</span>;
}
