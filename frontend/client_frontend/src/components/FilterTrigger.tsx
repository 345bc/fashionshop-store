"use client";
import { useState, useEffect } from "react";
import FilterSidebar from "./FilterSidebar";

export default function FilterTrigger() {
  const [isOpen, setIsOpen] = useState(false);
  useEffect(() => {
    document.body.style.overflow = isOpen ? "hidden" : "";
    return () => { document.body.style.overflow = ""; };
  }, [isOpen]);
  return <><button className="filter-action-btn" onClick={() => setIsOpen(true)}><span className="material-symbols-outlined" style={{ fontSize: 16 }}>tune</span>Bộ lọc</button><FilterSidebar isOpen={isOpen} onClose={() => setIsOpen(false)} /></>;
}
