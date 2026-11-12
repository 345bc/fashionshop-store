"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { apiRequest } from "@/api/apiClient";
import styles from "@/app/HomeCampaign.module.css";
import ProductRail from "./ProductRail";
import HomeScrollReveal, { useHomeSectionReady } from "./HomeScrollReveal";
import { reportConnectionFailure } from "@/api/apiClient";
import ProductCardSkeleton from "./skeleton-ui/ProductCardSkeleton";
import type { ProductCardData } from "@/type/product";

type Spotlight = { id: number; campaignName: string; imageUrl: string; products: ProductCardData[] };

export default function CampaignDisplays() {
  const ready = useHomeSectionReady();
  const [data, setData] = useState<Spotlight[]>([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    if (!ready) return;
    const controller = new AbortController();
    let disposed = false;
    const timeout = setTimeout(() => {
      if (disposed) return;
      reportConnectionFailure();
      controller.abort();
    }, 15000);
    apiRequest("/product/campaign-displays", { signal: controller.signal, cache: "no-store" })
      .then(response => { if (!controller.signal.aborted) setData(Array.isArray(response?.data) ? response.data : []); })
      .catch(() => { if (!controller.signal.aborted) reportConnectionFailure(); })
      .finally(() => { clearTimeout(timeout); if (!controller.signal.aborted) setLoading(false); });
    return () => { disposed = true; clearTimeout(timeout); controller.abort(); };
  }, [ready]);
  if (loading) return <div aria-label="Đang tải chương trình ưu đãi" aria-busy="true"><section className="campaign-fullwidth"><div className={`campaign-panel-full ${styles.panel} ${styles.skeleton}`} aria-hidden="true" /></section><div className="container mx-auto px-4 sm:px-6 lg:px-8 py-12"><ProductCardSkeleton count={4} /></div></div>;
  const displays = data.filter(item => item.products?.length);
  if (!displays.length) return null;
  return <>{displays.map(item => <CampaignBlock key={item.id} data={item} />)}</>;
}

function CampaignBlock({ data }: { data: Spotlight }) {
  const isVideo = /\.mp4(?:[?#]|$)/i.test(data.imageUrl);
  return <>
    <HomeScrollReveal>
    <section className="campaign-fullwidth" aria-label={data.campaignName}>
    <Link href={`/products?campaign=${data.id}`} aria-label={data.campaignName} className={`campaign-panel-full ${styles.panel}`}>
      {isVideo ? (
        <video src={data.imageUrl} className={styles.campaignImage} autoPlay muted loop playsInline aria-hidden="true" />
      ) : (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={data.imageUrl} alt="" className={styles.campaignImage} loading="lazy" />
      )}
    </Link>
    </section>
    </HomeScrollReveal>
    <HomeScrollReveal>
    <ProductRail title={data.campaignName} products={data.products.map(product => ({
      id: String(product.id), slug: product.slug, name: product.name,
      price: `${(product.salePrice ?? product.basePrice).toLocaleString("vi-VN")} VND`,
      originalPrice: product.salePrice != null && product.salePrice < product.basePrice ? `${product.basePrice.toLocaleString("vi-VN")} VND` : undefined,
      discountPercent: product.discountPercent, image: product.imageUrl ?? "", colors: product.colors,
      badge: product.badge ?? undefined, rating: product.averageRating, reviewsCount: product.reviewsCount,
    }))} />
    </HomeScrollReveal>
  </>;
}
