"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { apiRequest } from "@/api/apiClient";
import type { PageResponse } from "@/type/api";
import type { ProductCardData } from "@/type/product";
import ProductCard from "./ProductCard";
import ProductRail, { type ProductRailItem } from "./ProductRail";
import { useHomeSectionReady } from "./HomeScrollReveal";
import styles from "./HomeProductShowcase.module.css";

const collections = {
  new: { label: "SẢN PHẨM MỚI", href: "/products?new=1" },
  best: { label: "SẢN PHẨM NỔI BẬT", href: "/products/best-sellers" },
} as const;

type Collection = keyof typeof collections;

const formatPrice = (value: number) => value.toLocaleString("vi-VN") + " VND";

export default function HomeProductShowcase({ listing = false }: { listing?: boolean }) {
  const [collection, setCollection] = useState<Collection>(listing ? "best" : "new");

  return (
    <section className={listing
      ? `modern-container sm:px-6 lg:px-8 ${styles.section}`
      : `px-3.5 lg:px-8 ${styles.section}`}
      aria-label={listing ? "Sản phẩm bán chạy" : "Sản phẩm mới và bán chạy"}>
      {listing ? <h1 className={styles.heading}>Best Seller</h1> : (
        <div className={styles.header}>
          <div className={styles.tabs} role="group" aria-label="Nhóm sản phẩm">
            {(Object.keys(collections) as Collection[]).map(key => (
              <button key={key} type="button" aria-pressed={collection === key} onClick={() => setCollection(key)}>
                {collections[key].label}
              </button>
            ))}
          </div>
          <Link className={styles.viewAll} href={collections[collection].href}
            aria-label={"Xem tất cả " + collections[collection].label}>
            Xem tất cả
          </Link>
        </div>
      )}
      <ProductShelf key={collection} collection={collection} listing={listing} />
    </section>
  );
}

function ProductShelf({ collection, listing }: { collection: Collection; listing: boolean }) {
  const ready = useHomeSectionReady();
  const [products, setProducts] = useState<ProductCardData[] | null>(null);
  const [error, setError] = useState(false);
  const [retry, setRetry] = useState(0);
  useEffect(() => {
    if (!ready) return;
    const controller = new AbortController();
    const size = listing ? 24 : 8;
    const endpoint = collection === "new" ? `/product/new-arrivals?size=${size}`
      : `/product/featured/best-sellers?size=${size}`;

    async function load() {
      try {
        const response = await apiRequest(endpoint, {
          signal: controller.signal,
          cache: "no-store",
          localErrorHandling: true,
        });
        const items = collection === "new" ? (response.data as PageResponse<ProductCardData>)?.content : response.data;
        if (!Array.isArray(items)) throw new Error("Danh sách sản phẩm không hợp lệ.");
        if (!controller.signal.aborted) setProducts(items);
      } catch {
        if (!controller.signal.aborted) setError(true);
      }
    }

    void load();
    return () => controller.abort();
  }, [collection, listing, retry, ready]);

  if (error) return <div className={styles.message} role="alert">
    <p>Chưa tải được sản phẩm.</p>
    <button type="button" onClick={() => { setError(false); setRetry(value => value + 1); }}>Thử lại</button>
  </div>;

  if (!products) return <div className={styles.placeholders} role="status" aria-label="Đang tải sản phẩm">
    {Array.from({ length: 4 }, (_, index) => <div key={index} aria-hidden="true" />)}
  </div>;

  if (!products.length) return <p className={styles.message}>Hiện chưa có sản phẩm.</p>;

  const cards: ProductRailItem[] = products.map(product => ({
    id: String(product.id),
    slug: product.slug,
    name: product.name,
    image: product.imageUrl ?? "",
    colors: product.colors,
    badge: product.badge ?? undefined,
    price: formatPrice(product.salePrice ?? product.basePrice),
    originalPrice: product.salePrice != null && product.salePrice < product.basePrice
      ? formatPrice(product.basePrice) : undefined,
    discountPercent: product.discountPercent,
    rating: product.averageRating,
    reviewsCount: product.reviewsCount,
  }));

  if (!listing) return <ProductRail title={collections[collection].label} products={cards} embedded />;

  return (
    <ul className={styles.grid} aria-label={collections[collection].label}>
      {cards.map(card => (
        <li key={card.id} className={styles.card}>
          <ProductCard {...card} slug={card.slug ?? card.id} />
        </li>
      ))}
    </ul>
  );
}
