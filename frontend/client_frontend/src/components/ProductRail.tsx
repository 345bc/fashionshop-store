"use client";

import { useRef } from "react";
import Link from "next/link";
import ProductCard from "./ProductCard";

type ProductRailItem = {
  id: string;
  name: string;
  price: string;
  image: string;
  badge?: string;
  rating: number;
  reviewsCount: number;
};

type ProductRailProps = {
  title?: string;
  products: ProductRailItem[];
  href?: string;
};

export default function ProductRail({ title, products, href }: ProductRailProps) {
  const railRef = useRef<HTMLDivElement>(null);

  const move = (direction: -1 | 1) => {
    const rail = railRef.current;
    if (!rail) return;

    rail.scrollBy({
      left: direction * rail.clientWidth * 0.82,
      behavior: "smooth",
    });
  };

  return (
    <section className="home-section product-rail-section">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div ref={railRef} className="product-rail" tabIndex={0} aria-label={title ?? "Sản phẩm"}>
          {products.map((item) => <ProductCard key={item.id} {...item} />)}
        </div>
        <div className="product-rail-footer">
          <div aria-hidden="true" />
          <div className="product-rail-buttons" aria-label="Điều khiển sản phẩm">
            <button type="button" onClick={() => move(-1)} aria-label="Xem sản phẩm trước">
              <span className="material-symbols-outlined" style={{ fontSize: 18 }}>arrow_back</span>
            </button>
            <button type="button" onClick={() => move(1)} aria-label="Xem sản phẩm tiếp theo">
              <span className="material-symbols-outlined" style={{ fontSize: 18 }}>arrow_forward</span>
            </button>
          </div>
          {href && <Link href={href} className="product-rail-all">Xem tất cả sản phẩm <span className="material-symbols-outlined" style={{ fontSize: 15 }}>north_east</span></Link>}
        </div>
      </div>
    </section>
  );
}
