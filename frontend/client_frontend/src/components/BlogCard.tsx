"use client";
import Image from "next/image";
import Link from "next/link";

interface BlogCardProps {
  title: string;
  image: string;
  date: string;
  category: string;
  description: string;
  href: string;
}

export default function BlogCard({ href, title, image, date, category, description }: BlogCardProps) {
  return (
    <div className="blog-card-wrapper">
      <Link href={href} className="blog-card-link">
        <Image src={image} alt={title} fill style={{ objectFit: "cover" }} />
        <div className="blog-card-date">{date}</div>
        <div className="blog-card-content">
          <div className="blog-card-category"><span className="material-symbols-outlined" style={{ fontSize: 14 }}>sell</span>{category}</div>
          <h3 className="blog-card-title">{title}</h3>
          <div className="blog-card-desc-wrapper"><p className="blog-card-desc">{description}</p></div>
          <div className="blog-card-readmore">Đọc ngay <span className="material-symbols-outlined" style={{ fontSize: 16 }}>chevron_right</span></div>
        </div>
      </Link>
    </div>
  );
}
