"use client";

import { useState, useRef, useEffect } from "react";

export default function SortDropdown() {
  const [isOpen, setIsOpen] = useState(false);
  const [selected, setSelected] = useState("Sắp xếp theo");
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => { if (ref.current && !ref.current.contains(e.target as Node)) setIsOpen(false); };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);
  const options = ["Tiêu biểu", "Thấp đến cao", "Cao đến thấp", "Số sao"];
  return (
    <div className="sort-dropdown-container" ref={ref} style={{ position: "relative" }}>
      <button className="filter-action-btn" onClick={() => setIsOpen(!isOpen)}><span className="material-symbols-outlined" style={{ fontSize: 16 }}>swap_vert</span>{selected === "Sắp xếp theo" ? selected : `Sắp xếp: ${selected}`}</button>
      {isOpen && <div className="sort-dropdown-menu" style={{position:"absolute",top:"100%",right:0,marginTop:8,background:"#fff",border:"1px solid #eaeaea",borderRadius:8,boxShadow:"0 4px 12px rgba(0,0,0,.1)",zIndex:10,minWidth:180,overflow:"hidden"}}>{options.map((opt) => <button key={opt} style={{display:"block",width:"100%",textAlign:"left",padding:"10px 16px",border:"none",background:selected===opt?"#f5f5f5":"transparent",cursor:"pointer",fontSize:".95rem"}} onClick={() => { setSelected(opt); setIsOpen(false); }}>{opt}</button>)}</div>}
    </div>
  );
}
