import { apiRequest } from "@/api/apiClient";
import type { ProductCardData } from "@/type/product";

type FeaturedResult = { products: { product: ProductCardData }[]; title: string; description: string | null; isDisplay: boolean };
export type FeaturedDisplay = { products: ProductCardData[]; title: string; description: string | null; isDisplay: boolean };

export async function featuredProducts(signal?: AbortSignal): Promise<FeaturedDisplay> {
  const response = await apiRequest("/product/featured?size=8", { signal, cache: "no-store" });
  const data = response?.data as FeaturedResult | undefined;
  if (!Array.isArray(data?.products) || typeof data.title !== "string" || typeof data.isDisplay !== "boolean") throw new Error("Không tải được sản phẩm nổi bật. Vui lòng thử lại.");
  const products = data.products.map(item => item?.product);
  if (products.some(p => !p || !Number.isSafeInteger(p.id) || p.id <= 0 || !p.slug || !p.name || !Number.isFinite(p.basePrice) || p.basePrice < 0))
    throw new Error("Dữ liệu sản phẩm nổi bật chưa hợp lệ. Vui lòng thử lại.");
  return { products: data.isDisplay ? products : [], title: data.title, description: data.description, isDisplay: data.isDisplay };
}
