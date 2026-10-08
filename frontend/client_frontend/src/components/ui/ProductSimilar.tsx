"use client";

import { useEffect, useState } from "react";
import { getSimilars } from "@/service/productService";
import type { ProductCardData } from "@/type/product";
import ProductCardSkeleton from "@/components/skeleton-ui/ProductCardSkeleton";
import ProductRail from "@/components/ProductRail";

export default function ProductSimilar({ productId }: { productId: number }) {
    const [products, setProducts] = useState<ProductCardData[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");
    const [retry, setRetry] = useState(0);

    useEffect(() => {
        const controller = new AbortController();
        let timer: ReturnType<typeof setTimeout> | undefined;
        async function load() {
            setLoading(true);
            setError("");
            try {
                const response = await getSimilars({ productId, size: 8, signal: controller.signal });
                if (controller.signal.aborted) return;
                setProducts(response.data.content);
                setLoading(false);
            } catch (err) {
                if (controller.signal.aborted) return;
                if (err instanceof TypeError) {
                    timer = setTimeout(() => setRetry(value => value + 1), 5000);
                } else {
                    setError(err instanceof Error ? err.message : "Không tải được sản phẩm ");
                    setLoading(false);
                }
            }
        }
        void load();
        return () => { controller.abort(); clearTimeout(timer); };
    }, [productId, retry]);

    if (!loading && !error && products.length === 0) return null;

    if (loading || error) {
        return (
            <div className="product-related-rails" style={{ marginTop: 64 }}>
                <section className="home-section product-rail-section">
                    <div className="container mx-auto px-4 sm:px-6 lg:px-8">
                        {loading ? <ProductCardSkeleton /> : <div role="alert">
                            <p>{error}</p>
                            <button type="button" onClick={() => setRetry(value => value + 1)}>Thử lại</button>
                        </div>}
                    </div>
                </section>
            </div>
        );
    }

    return (
        <div className="product-related-rails" style={{ marginTop: 64 }}>
            <div className="container mx-auto px-4 sm:px-6 lg:px-8">
                <h2 className="slider-section-title" style={{ marginBottom: 12, fontSize: "1.5rem" }}>Sản phẩm tương tự</h2>
            </div>
            <ProductRail title="Sản phẩm tương tự" products={products.map(product => ({
                id: String(product.id),
                slug: product.slug,
                name: product.name,
                price: `${product.basePrice.toLocaleString("vi-VN")}₫`,
                image: product.imageUrl ?? "",
                colors: product.colors,
                badge: product.badge ?? "",
            }))} />
        </div>
    );

}
