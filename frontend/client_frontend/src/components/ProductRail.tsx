"use client";

import { useEffect, useRef, useState, type ComponentProps } from "react";
import ProductCard from "./ProductCard";
import styles from "./ProductRail.module.css";

export type ProductRailItem = Omit<ComponentProps<typeof ProductCard>, "slug"> & { slug?: string };

type ProductRailProps = {
  title?: string;
  products: ProductRailItem[];
  embedded?: boolean;
};

export default function ProductRail({ title, products, embedded = false }: ProductRailProps) {
  const railRef = useRef<HTMLDivElement>(null);
  const [canPrevious, setCanPrevious] = useState(false);
  const [canNext, setCanNext] = useState(false);

  useEffect(() => {
    const rail = railRef.current;
    if (!rail) return;

    const update = () => {
      setCanPrevious(rail.scrollLeft > 2);
      setCanNext(rail.scrollLeft + rail.clientWidth < rail.scrollWidth - 2);
    };
    const observer = new ResizeObserver(update);
    observer.observe(rail);
    rail.addEventListener("scroll", update, { passive: true });
    update();
    return () => {
      observer.disconnect();
      rail.removeEventListener("scroll", update);
    };
  }, [products.length]);

  const move = (direction: -1 | 1) => {
    const rail = railRef.current;
    if (!rail) return;

    rail.scrollBy({
      left: direction * rail.clientWidth * 0.82,
      behavior: window.matchMedia("(prefers-reduced-motion: reduce)").matches ? "instant" : "smooth",
    });
  };

  return (
    <section className={embedded ? `${styles.section} ${styles.embedded}` : `home-section product-rail-section ${styles.section}`}>
      <div className={embedded ? undefined : "container mx-auto px-4 sm:px-6 lg:px-8"}>
        <div className={styles.carousel}>
          <div ref={railRef} className={`product-rail ${styles.track}`} tabIndex={0} aria-label={title ?? "Sản phẩm"}>
            {products.map((item) => <ProductCard key={item.id} {...item} slug={item.slug ?? item.id} />)}
          </div>
          <button type="button" className={styles.previous} disabled={!canPrevious}
            onClick={() => move(-1)} aria-label="Xem sản phẩm trước" />
          <button type="button" className={styles.next} disabled={!canNext}
            onClick={() => move(1)} aria-label="Xem sản phẩm tiếp theo" />
        </div>
      </div>
    </section>
  );
}
