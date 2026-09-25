"use client";

import { useMemo, useState } from "react";
import ProductCard from "./ProductCard";
import FilterSidebar from "./FilterSidebar";

type Product = {
  id: string;
  name: string;
  price: number;
  image: string;
  type: string;
  sizes: string[];
  badge?: string;
  rating: number;
  reviewsCount: number;
};

type FilterState = { types: string[]; sizes: string[]; price: string };

const products: Product[] = [
  { id: "1", name: "Áo sơ mi Relaxed Linen", price: 429000, image: "/assets/images/v7_1725.png", type: "Áo", sizes: ["S","M","L"], badge: "Mới", rating: 4.9, reviewsCount: 42 },
  { id: "2", name: "Quần suông Soft Tailoring", price: 549000, image: "/assets/images/v7_1730.png", type: "Quần", sizes: ["S","M","L","XL"], rating: 4.8, reviewsCount: 61 },
  { id: "3", name: "Váy midi Sage Flow", price: 679000, image: "/assets/images/v7_1916.png", type: "Váy & đầm", sizes: ["XS","S","M","L"], badge: "Best seller", rating: 4.9, reviewsCount: 128 },
  { id: "4", name: "Set vest Modern Balance", price: 899000, image: "/assets/images/v7_1951.png", type: "Áo khoác", sizes: ["S","M","L"], rating: 4.8, reviewsCount: 30 },
  { id: "5", name: "Đầm satin Sand Drape", price: 729000, image: "/assets/images/v7_1937.png", type: "Váy & đầm", sizes: ["S","M","L"], badge: "Limited", rating: 4.7, reviewsCount: 34 },
  { id: "6", name: "Quần ống rộng Cocoa", price: 489000, image: "/assets/images/v7_1923.png", type: "Quần", sizes: ["S","M","L","XL"], rating: 4.8, reviewsCount: 57 },
  { id: "7", name: "Áo dệt kim Ivory Air", price: 299000, image: "/assets/images/v7_2123.png", type: "Áo", sizes: ["XS","S","M","L"], rating: 4.6, reviewsCount: 23 },
  { id: "8", name: "Túi cói Studio Basket", price: 359000, image: "/assets/images/v7_1944.png", type: "Phụ kiện", sizes: ["M"], badge: "Mới", rating: 4.9, reviewsCount: 49 },
  { id: "9", name: "Váy midi Olive Line", price: 619000, image: "/assets/images/v7_2020.png", type: "Váy & đầm", sizes: ["S","M","L"], rating: 4.8, reviewsCount: 75 },
  { id: "10", name: "Áo dài tay Minimal Knit", price: 329000, image: "/assets/images/v7_1909.png", type: "Áo", sizes: ["S","M","L","XL"], rating: 4.7, reviewsCount: 18 },
  { id: "11", name: "Chân váy Sage Pleat", price: 459000, image: "/assets/images/v7_2019.png", type: "Váy & đầm", sizes: ["XS","S","M","L"], rating: 4.9, reviewsCount: 66 },
  { id: "12", name: "Blazer Taupe Structure", price: 799000, image: "/assets/images/v7_1713.png", type: "Áo khoác", sizes: ["S","M","L","XL"], rating: 4.8, reviewsCount: 39 },
];

const formatPrice = (price: number) => `${price.toLocaleString("vi-VN")}₫`;

function initialTypes(category: string) {
  if (category.includes("vay")) return ["Váy & đầm"];
  if (category.includes("quan")) return ["Quần"];
  if (category.includes("khoac")) return ["Áo khoác"];
  if (category.includes("phu-kien")) return ["Phụ kiện"];
  if (category.includes("ao")) return ["Áo"];
  return [];
}

export default function ProductCatalog({ initialQuery = "", initialCategory = "" }: { initialQuery?: string; initialCategory?: string }) {
  const [filterOpen, setFilterOpen] = useState(false);
  const [filters, setFilters] = useState<FilterState>({ types: initialTypes(initialCategory), sizes: [], price: "all" });
  const [sort, setSort] = useState("featured");
  const [query, setQuery] = useState(initialQuery.trim());

  const filtered = useMemo(() => {
    const q = query.toLocaleLowerCase("vi");
    let list = products.filter((product) => {
      const queryMatch = !q || product.name.toLocaleLowerCase("vi").includes(q) || product.type.toLocaleLowerCase("vi").includes(q);
      const typeMatch = filters.types.length === 0 || filters.types.includes(product.type);
      const sizeMatch = filters.sizes.length === 0 || filters.sizes.some((size) => product.sizes.includes(size));
      const priceMatch = filters.price === "all" ||
        (filters.price === "under300" && product.price < 300000) ||
        (filters.price === "300to500" && product.price >= 300000 && product.price <= 500000) ||
        (filters.price === "over500" && product.price > 500000);
      return queryMatch && typeMatch && sizeMatch && priceMatch;
    });
    if (sort === "low") list = [...list].sort((a,b) => a.price - b.price);
    if (sort === "high") list = [...list].sort((a,b) => b.price - a.price);
    if (sort === "rating") list = [...list].sort((a,b) => b.rating - a.rating);
    return list;
  }, [filters, sort, query]);

  return (
    <>
      <section className="catalog-hero">
        <div>
          <span className="eyebrow">ZELLA / SHOP</span>
          <h1>{query ? `Kết quả cho “${query}”` : "Tất cả sản phẩm"}</h1>
          <p>Những thiết kế dễ mặc, bảng màu trung tính và phom dáng hiện đại cho tủ đồ mỗi ngày.</p>
        </div>
        <div className="catalog-hero-count">{filtered.length}<span>sản phẩm</span></div>
      </section>

      <div className="catalog-toolbar">
        <div className="catalog-toolbar-left">
          <button className="catalog-filter-btn" onClick={() => setFilterOpen(true)}><span className="material-symbols-outlined" style={{ fontSize: 17 }}>tune</span> Bộ lọc</button>
          {(filters.types.length > 0 || filters.sizes.length > 0 || filters.price !== "all") && (
            <button className="catalog-clear-inline" onClick={() => setFilters({ types: [], sizes: [], price: "all" })}>Xóa bộ lọc</button>
          )}
        </div>
        <label className="catalog-sort">
          <span>Sắp xếp</span>
          <select value={sort} onChange={(e) => setSort(e.target.value)}>
            <option value="featured">Nổi bật</option>
            <option value="low">Giá thấp đến cao</option>
            <option value="high">Giá cao đến thấp</option>
            <option value="rating">Đánh giá cao nhất</option>
          </select>
        </label>
      </div>

      {filtered.length > 0 ? (
        <div className="modern-products-grid">
          {filtered.map((product) => (
            <ProductCard key={product.id} {...product} price={formatPrice(product.price)} />
          ))}
        </div>
      ) : (
        <div className="empty-catalog">
          <h2>Chưa có sản phẩm phù hợp</h2>
          <p>Hãy thử bỏ bớt bộ lọc hoặc tìm bằng từ khóa khác.</p>
          <button onClick={() => { setFilters({ types: [], sizes: [], price: "all" }); setQuery(""); }}>Xem tất cả sản phẩm</button>
        </div>
      )}

      <FilterSidebar isOpen={filterOpen} onClose={() => setFilterOpen(false)} value={filters} onChange={setFilters} resultCount={filtered.length} />
    </>
  );
}
