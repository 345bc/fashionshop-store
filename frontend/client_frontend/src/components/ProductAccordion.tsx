"use client";
import GoogleSymbol from "@/components/ui/GoogleSymbol";

import { useState } from "react";

interface ProductAccordionProps {
  title: string;
  children: React.ReactNode;
  defaultOpen?: boolean;
}

export default function ProductAccordion({ title, children, defaultOpen = false }: ProductAccordionProps) {
  const [isOpen, setIsOpen] = useState(defaultOpen);

  return (
    <div className="desc-accordion-item">
      <div className="desc-accordion-header" onClick={() => setIsOpen(!isOpen)}>
        <span>{title}</span>
        <span style={{ fontSize: "1.2rem", fontWeight: 300 }}><GoogleSymbol name={isOpen ? "remove" : "add"} size={20} /></span>
      </div>
      {isOpen && (
        <div className="desc-accordion-content">
          {children}
        </div>
      )}
    </div>
  );
}
