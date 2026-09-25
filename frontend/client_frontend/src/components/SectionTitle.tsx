import React from "react";

interface SectionTitleProps {
  title: string;
  description?: string;
  align?: string; // center or left
}

export default function SectionTitle({ title, description, align = "center" }: SectionTitleProps) {
  const alignment = align.includes("left") ? "left" : "center";

  return (
    <div className="section-header" style={{ textAlign: alignment, marginBottom: "32px" }}>
      <h2 className="section-title" style={{ fontSize: "1.8rem", fontFamily: "var(--font-sans)", fontWeight: "500", color: "var(--ink-primary)", marginBottom: "12px", letterSpacing: "0.2px" }}>
        {title}
      </h2>
      {description && (
        <p className="section-desc" style={{ color: "var(--ink-secondary)", maxWidth: "600px", margin: alignment === "center" ? "0 auto" : "0", lineHeight: "1.6", fontSize: "0.95rem" }}>
          {description}
        </p>
      )}
    </div>
  );
}
