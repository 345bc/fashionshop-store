"use client";

import { useEffect, useId, useRef, useState } from "react";
import ProductCard from "./ProductCard";
import ProductCardSkeleton from "./skeleton-ui/ProductCardSkeleton";
import { featuredProducts } from "@/service/featuredProductService";
import type { ProductCardData } from "@/type/product";
import styles from "./FeaturedProducts.module.css";

const price = (value: number) => `${value.toLocaleString("vi-VN")} VND`;

export default function FeaturedProducts() {
  const [products, setProducts] = useState<ProductCardData[]>([]);
  const [title, setTitle] = useState("Sản phẩm nổi bật");
  const [description, setDescription] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [retry, setRetry] = useState(0);
  const [canPrevious, setCanPrevious] = useState(false);
  const [canNext, setCanNext] = useState(false);
  const track = useRef<HTMLUListElement>(null);
  const titleId = useId();
  useEffect(() => {
    const controller = new AbortController();
    featuredProducts(controller.signal)
      .then(data => { if (!controller.signal.aborted) { setProducts(data.products); setTitle(data.title); setDescription(data.description); } })
      .catch(() => { if (!controller.signal.aborted) setError(true); })
      .finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [retry]);
  useEffect(() => {
    const element = track.current;
    if (!element) return;
    const update = () => {
      setCanPrevious(element.scrollLeft > 2);
      setCanNext(element.scrollLeft + element.clientWidth < element.scrollWidth - 2);
    };
    update();
    const observer = new ResizeObserver(update);
    observer.observe(element);
    element.addEventListener("scroll", update, { passive: true });
    return () => { observer.disconnect(); element.removeEventListener("scroll", update); };
  }, [products, loading, error]);
  const move = (direction: number) => {
    const element = track.current;
    element?.scrollBy({ left: direction * element.clientWidth, behavior: window.matchMedia("(prefers-reduced-motion: reduce)").matches ? "instant" : "smooth" });
  };
  if (!loading && !error && !products.length) return null;
  return <section className={styles.section} aria-labelledby={titleId} aria-busy={loading}>
    <div className={`container mx-auto ${styles.container}`}>
      <div className={styles.header}>
        <div>
          <p className={styles.eyebrow}>GỢI Ý DÀNH CHO BẠN</p>
          <h2 id={titleId} className={styles.title}>{title}</h2>
          {description && <p className={styles.description}>{description}</p>}
        </div>
        {!loading && !error && <div className={styles.navigation}>
          <span className={styles.count}>{products.length} thiết kế</span>
          <button type="button" disabled={!canPrevious} onClick={() => move(-1)} aria-label="Xem sản phẩm nổi bật trước"><span aria-hidden="true">←</span></button>
          <button type="button" disabled={!canNext} onClick={() => move(1)} aria-label="Xem sản phẩm nổi bật tiếp theo"><span aria-hidden="true">→</span></button>
        </div>}
      </div>
      {loading ? <ProductCardSkeleton count={4} /> : error ? <div className={styles.error} role="alert">
        <p>Chưa tải được sản phẩm nổi bật.</p><button type="button" onClick={() => { setError(false); setLoading(true); setRetry(n => n + 1); }}>Thử lại <span aria-hidden="true">↻</span></button>
      </div> : <ul ref={track} className={styles.track} tabIndex={0} aria-label="Danh sách sản phẩm nổi bật">
        {products.map(product => <li key={product.id} className={styles.item}>
          <ProductCard id={String(product.id)} slug={product.slug} name={product.name}
            image={product.imageUrl ?? ""} colors={product.colors} badge="Nổi bật"
            price={price(product.salePrice ?? product.basePrice)}
            originalPrice={product.salePrice != null && product.salePrice < product.basePrice ? price(product.basePrice) : undefined}
            discountPercent={product.discountPercent} rating={product.averageRating} reviewsCount={product.reviewsCount} />
        </li>)}
      </ul>}
    </div>
  </section>;
}
