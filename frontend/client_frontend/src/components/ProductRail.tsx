"use client";

import { useRef, type ComponentProps } from "react";
import ProductCard from "./ProductCard";

type ProductRailItem = Omit<ComponentProps<typeof ProductCard>, "slug"> & { slug?: string };

type ProductRailProps = {
  title?: string;
  products: ProductRailItem[];
  href?: string;
};

export default function ProductRail({ title, products }: ProductRailProps) {
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
          {products.map((item) => <ProductCard key={item.id} {...item} slug={item.slug ?? item.id} />)}
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
          <div aria-hidden="true" />
        </div>
      </div>
    </section>
  );
}
