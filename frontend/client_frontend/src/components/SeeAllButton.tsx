"use client";
import Link from "next/link";
import React from "react";

interface SeeAllButtonProps {
  href: string;
  label?: string;
  className?: string;
}

export default function SeeAllButton({
  href,
  label = "Xem thêm",
  className = "",
}: SeeAllButtonProps) {
  return (
    <div className={`see-all-wrapper ${className}`}>
      <Link href={href} className="btn-see-all group">
        <span>{label}</span>
      </Link>
    </div>
  );
}
