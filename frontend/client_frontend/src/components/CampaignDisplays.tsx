"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { apiRequest } from "@/api/apiClient";
import styles from "@/app/HomeCampaign.module.css";
import ProductRail from "./ProductRail";
import ConnectionError from "./ConnectionError";
import ProductCardSkeleton from "./skeleton-ui/ProductCardSkeleton";
import type { ProductCardData } from "@/type/product";

type Spotlight = { id: number; targetMode: string; campaignName: string; title: string; description: string | null; imageUrl: string; products: ProductCardData[]; startsAt: string | null; endsAt: string | null };

const campaignDate = (value: string) => new Intl.DateTimeFormat("vi-VN", {
  timeZone: "Asia/Ho_Chi_Minh", day: "2-digit", month: "2-digit", year: "numeric",
}).format(new Date(value));

export default function CampaignDisplays() {
  const [data, setData] = useState<Spotlight[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [retry, setRetry] = useState(0);
  useEffect(() => {
    const controller = new AbortController();
    let disposed = false;
    const timeout = setTimeout(() => { if (!disposed) { setError(true); setLoading(false); controller.abort(); } }, 15000);
    apiRequest("/product/campaign-displays", { signal: controller.signal, cache: "no-store" })
      .then(response => { if (!controller.signal.aborted) setData(Array.isArray(response?.data) ? response.data : []); })
      .catch(() => { if (!controller.signal.aborted) setError(true); })
      .finally(() => { clearTimeout(timeout); if (!controller.signal.aborted) setLoading(false); });
    return () => { disposed = true; clearTimeout(timeout); controller.abort(); };
  }, [retry]);
  if (loading) return <div aria-label="Đang tải chương trình ưu đãi" aria-busy="true"><section className="campaign-fullwidth"><div className={`campaign-panel-full ${styles.panel} ${styles.skeleton}`} aria-hidden="true"><div className={`container mx-auto ${styles.spotlightContent}`}><div className={styles.skeletonTitle} /><div className={styles.skeletonDescription} /><div className={styles.skeletonDescription} /></div></div></section><div className="container mx-auto px-4 sm:px-6 lg:px-8 py-12"><ProductCardSkeleton count={4} /></div></div>;
  if (error) return <ConnectionError onRetry={() => { setError(false); setLoading(true); setRetry(n => n + 1); }} />;
  const displays = data.filter(item => item.products?.length);
  if (!displays.length) return null;
  return <>{displays.map(item => <CampaignBlock key={item.id} data={item} />)}</>;
}

function CampaignBlock({ data }: { data: Spotlight }) {
  return <>
    <section className="campaign-fullwidth" aria-label={data.campaignName}>
    <Link href={`#campaign-products-${data.id}`} className={`campaign-panel-full ${styles.panel}`}>
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src={data.imageUrl} alt={data.title} className={`${styles.productImage} ${styles.campaignImage}`} loading="lazy" />
      <div className={`container mx-auto ${styles.spotlightContent}`}>
        <h2 className={styles.productName}>{data.title}</h2>
        {data.description && <p className={styles.description}>{data.description}</p>}
        {data.targetMode === "SELECTED" && data.startsAt && data.endsAt &&
          Number.isFinite(Date.parse(data.startsAt)) && Number.isFinite(Date.parse(data.endsAt)) &&
          <p className={styles.campaignPeriod}>Ưu đãi có hạn từ <time dateTime={data.startsAt}>{campaignDate(data.startsAt)}</time> đến <time dateTime={data.endsAt}>{campaignDate(data.endsAt)}</time></p>}
      </div>
    </Link>
    </section>
    <div id={`campaign-products-${data.id}`} className="scroll-mt-24">
    <ProductRail title={data.campaignName} products={data.products.map(product => ({
      id: String(product.id), slug: product.slug, name: product.name,
      price: `${(product.salePrice ?? product.basePrice).toLocaleString("vi-VN")} VND`,
      originalPrice: product.salePrice != null && product.salePrice < product.basePrice ? `${product.basePrice.toLocaleString("vi-VN")} VND` : undefined,
      discountPercent: product.discountPercent, image: product.imageUrl ?? "", colors: product.colors,
      badge: product.badge ?? undefined, rating: product.averageRating, reviewsCount: product.reviewsCount,
    }))} />
    </div>
  </>;
}
