"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import ProductCard from "./ProductCard";
import ProductCardSkeleton from "./skeleton-ui/ProductCardSkeleton";
import FilterSidebar from "./FilterSidebar";
import { getProductCards, getNewArrivals } from "../service/productService";
import type { ApiResponse, PageResponse } from "../type/api";
import type { ProductCardData } from "../type/product";

type ProductCardsResponse =
  ApiResponse<PageResponse<ProductCardData>>;

type FilterState = { types: string[]; sizes: string[]; price: string };

const formatPrice = (price: number) => `${price.toLocaleString("vi-VN")}₫`;

const sortOptions = [
  { value: "featured", label: "Mới nhất" },
  { value: "low", label: "Giá thấp đến cao" },
  { value: "high", label: "Giá cao đến thấp" },
];

export default function ProductCatalog({
  initialQuery = "",
  initialCategory = "",
  initialCategoryName = "",
  newArrivalsOnly = false,
}: {
  initialQuery?: string;
  initialCategory?: string;
  initialCategoryName?: string;
  newArrivalsOnly?: boolean;
}) {
  // 1. Trạng thái khởi tạo / Truy vấn
  const [query, setQuery] = useState(initialQuery.trim());
  const [categoryId, setCategoryId] = useState<number | null>(
    /^[1-9]\d*$/.test(initialCategory) ? Number(initialCategory) : null
  );

  // 2. Trạng thái dữ liệu
  const [products, setProducts] = useState<ProductCardData[]>([]);
  const [totalProducts, setTotalProducts] = useState(0);

  // 3. Trạng thái phân trang
  const [page, setPage] = useState(0);
  const currentPage = page + 1;
  const [totalPages, setTotalPages] = useState(0);

  // 4. Trạng thái bộ lọc & sắp xếp
  const [filterOpen, setFilterOpen] = useState(false);
  const [sortOpen, setSortOpen] = useState(false);
  const [sort, setSort] = useState("featured");
  const [filters, setFilters] = useState<FilterState>({ types: [], sizes: [], price: "all" });
  const [selectedColorIds, setSelectedColorIds] = useState<number[]>([]);
  const [selectedSizeIds, setSelectedSizeIds] = useState<number[]>([]);

  const selectedFilterCount =
    selectedColorIds.length +
    selectedSizeIds.length +
    filters.types.length +
    (filters.price !== "all" ? 1 : 0);

  // 5. Trạng thái tải & lỗi
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [connectionLost, setConnectionLost] = useState(false);
  const [productRetry, setProductRetry] = useState(0);
  const productsLoading = loading || connectionLost;

  //Lọc giá
  let minPrice: number | null = null;
  let maxPrice: number | null = null;

  if (filters.price === "under199") {
    maxPrice = 198999;
  } else if (filters.price === "199to299") {
    minPrice = 199000;
    maxPrice = 299000;
  } else if (filters.price === "299to399") {
    minPrice = 299000;
    maxPrice = 399000;
  } else if (filters.price === "399to499") {
    minPrice = 399000;
    maxPrice = 499000;
  } else if (filters.price === "499to799") {
    minPrice = 499000;
    maxPrice = 799000;
  } else if (filters.price === "799to999") {
    minPrice = 799000;
    maxPrice = 999000;
  } else if (filters.price === "over999") {
    minPrice = 999000;
  }


  useEffect(() => {
    const controller = new AbortController();
    let retryTimer: ReturnType<typeof setTimeout> | undefined;

    async function loadProducts() {
      setLoading(true);
      setError("");

      try {
        const response: ProductCardsResponse = newArrivalsOnly
          ? await getNewArrivals({ page, size: 12, signal: controller.signal })
          : await getProductCards({
            q: query,
            categoryId,
            page,
            size: 12,
            sort,
            colorIds: selectedColorIds,
            sizeIds: selectedSizeIds,
            minPrice,
            maxPrice,
            signal: controller.signal,
          });

        if (controller.signal.aborted) return;

        setConnectionLost(false);
        setTotalProducts(response.data.totalElements);

        setProducts(response.data.content);
        setTotalPages(response.data.totalPages);
      } catch (err) {
        if (controller.signal.aborted) return;

        if (err instanceof TypeError) {
          setConnectionLost(true);
          retryTimer = setTimeout(() => setProductRetry((value) => value + 1), 5000);
        } else {
          setConnectionLost(false);
          setError(err instanceof Error ? err.message : "Không tải được sản phẩm");
        }
      } finally {
        if (!controller.signal.aborted) {
          setLoading(false);
        }
      }
    }

    loadProducts();

    return () => {
      controller.abort();
      clearTimeout(retryTimer);
    };
  }, [query, categoryId, page, sort, selectedColorIds, selectedSizeIds, minPrice, maxPrice, productRetry, newArrivalsOnly]);

  function toggleColor(colorId: number) {
    setSelectedColorIds((previous) =>
      previous.includes(colorId)
        ? previous.filter((id) => id !== colorId)
        : [...previous, colorId]
    );

    setPage(0);
  }

  function toggleSize(sizeId: number) {
    setSelectedSizeIds((previous) =>
      previous.includes(sizeId)
        ? previous.filter((id) => id !== sizeId)
        : [...previous, sizeId]
    );

    setPage(0);
  }

  function clearFilters() {
    setFilters({ types: [], sizes: [], price: "all" });
    setSelectedColorIds([]);
    setSelectedSizeIds([]);
    setPage(0);
  }

  // const filtered = useMemo(() => {
  //   const q = query.toLocaleLowerCase("vi");
  //   let list = products.filter((product) => {
  //     const queryMatch = !q || product.name.toLocaleLowerCase("vi").includes(q) || product.type.toLocaleLowerCase("vi").includes(q);
  //     const typeMatch = filters.types.length === 0 || filters.types.includes(product.type);
  //     const sizeMatch = filters.sizes.length === 0 || filters.sizes.some((size) => product.sizes.includes(size));
  //     const priceMatch = filters.price === "all" ||
  //       (filters.price === "under300" && product.price < 300000) ||
  //       (filters.price === "300to500" && product.price >= 300000 && product.price <= 500000) ||
  //       (filters.price === "over500" && product.price > 500000);
  //     return queryMatch && typeMatch && sizeMatch && priceMatch;
  //   });
  //   if (sort === "low") list = [...list].sort((a, b) => a.price - b.price);
  //   if (sort === "high") list = [...list].sort((a, b) => b.price - a.price);
  //   if (sort === "rating") list = [...list].sort((a, b) => b.rating - a.rating);
  //   return list;
  // }, [filters, sort, query]);




  return (
    <>
      <section className="catalog-hero">
        <div>
          <h1>
            {newArrivalsOnly ? "Sản phẩm mới" : query
              ? `Kết quả tìm kiếm cho “${query}”`
              : categoryId !== null
                ? `Kết quả tìm kiếm cho ${initialCategoryName || "danh mục đã chọn"}`
                : "Tất cả sản phẩm"}
          </h1>
          <p>{newArrivalsOnly ? "Các thiết kế mới ra mắt trong 7 ngày gần nhất, sắp xếp mới nhất trước." : "Những thiết kế dễ mặc, bảng màu trung tính và phom dáng hiện đại cho tủ đồ mỗi ngày."}</p>
        </div>
        <div className="catalog-hero-count">{totalProducts}<span>sản phẩm</span></div>
      </section>

      {!newArrivalsOnly && <div className="mb-6 mt-2 flex flex-col justify-between gap-3 border-b border-black/10 pb-4 sm:flex-row sm:items-center">
        <div className="flex items-center gap-4">
          <button
            className="flex h-9 items-center justify-center gap-2 rounded-full border border-black/20 bg-white px-5 text-[13px] font-semibold tracking-wide text-black transition-all hover:border-black hover:bg-black/5 active:scale-[0.98]"
            onClick={() => setFilterOpen(true)}
            aria-label={`Mở bộ lọc, ${selectedFilterCount} lựa chọn đang được chọn`}
          >
            <span className="material-symbols-outlined" style={{ fontSize: 16, strokeWidth: 2 }}>tune</span>
            BỘ LỌC
            {selectedFilterCount > 0 && (
              <span className="flex size-5 items-center justify-center rounded-full bg-black text-[11px] font-bold text-white">
                {selectedFilterCount}
              </span>
            )}
          </button>

          {selectedFilterCount > 0 && (
            <button
              className="text-[13px] font-medium text-black/40 underline-offset-4 transition-colors hover:text-black hover:underline"
              onClick={clearFilters}
            >
              Xóa bộ lọc
            </button>
          )}
        </div>

        <div className="flex items-center gap-2">
          <span className="text-[13px] font-medium text-black/50">Sắp xếp theo</span>
          <div className="relative">
            <button
              onClick={() => setSortOpen(!sortOpen)}
              className="flex w-36.25 items-center justify-between gap-1 bg-transparent text-[14px] font-bold text-black outline-none transition-colors hover:text-black/70"
            >
              <span className="flex-1 truncate text-left">
                {sortOptions.find((opt) => opt.value === sort)?.label}
              </span>
              <span className={`material-symbols-outlined shrink-0 text-[18px] transition-transform duration-300 ${sortOpen ? "rotate-180" : ""}`}>expand_more</span>
            </button>

            {sortOpen && (
              <>
                <div className="fixed inset-0 z-40" onClick={() => setSortOpen(false)} />
                <div className="absolute right-0 top-full z-50 mt-2 w-48 overflow-hidden rounded-xl bg-white py-2 shadow-2xl ring-1 ring-black/5 animate-in fade-in slide-in-from-top-2">
                  {sortOptions.map((opt) => (
                    <button
                      key={opt.value}
                      onClick={() => {
                        setSort(opt.value);
                        setPage(0);
                        setSortOpen(false);
                      }}
                      className={`flex w-full items-center justify-between px-4 py-2.5 text-left text-[14px] transition-colors hover:bg-black/5 ${sort === opt.value ? "font-bold text-black" : "font-medium text-black/60 hover:text-black"}`}
                    >
                      {opt.label}
                      {sort === opt.value && <span className="material-symbols-outlined text-[16px]">check</span>}
                    </button>
                  ))}
                </div>
              </>
            )}
          </div>
        </div>
      </div>}

      {productsLoading && products.length === 0 ? (
        <ProductCardSkeleton />
      ) : error ? (
        <p role="alert">{error}</p>
      ) : products.length > 0 ? (
        <div className="grid" aria-busy={productsLoading}>
          {productsLoading && (
            <div className="col-start-1 row-start-1">
              <ProductCardSkeleton />
            </div>
          )}
          <div className={`col-start-1 row-start-1 ${productsLoading ? "invisible" : ""}`} aria-hidden={productsLoading}>
            <div className="modern-products-grid">
              {products.map((product) => (
                <ProductCard
                  key={product.id}
                  id={String(product.id)}
                  slug={product.slug}
                  name={product.name}
                  price={formatPrice(product.basePrice)}
                  image={product.imageUrl ?? ""}
                  colors={product.colors}
                  badge={product.badge || undefined}
                />
              ))}
            </div>

            {totalPages > 1  && (
              <div className="mt-14 flex items-center justify-center gap-6">
                <button
                  disabled={currentPage === 1}
                  onClick={() => {
                    setPage(prev => prev - 1);
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                  }}
                  className="flex items-center justify-center text-black transition-opacity hover:opacity-60 disabled:opacity-20"
                  aria-label="Trang trước"
                >
                  <span className="material-symbols-outlined" style={{ fontSize: 24, strokeWidth: 1 }}>chevron_left</span>
                </button>

                <div className="flex items-center gap-2">
                  {(function () {
                    let pages: (number | string)[] = [];
                    if (totalPages <= 7) {
                      pages = Array.from({ length: totalPages }, (_, i) => i + 1);
                    } else {
                      if (currentPage <= 4) {
                        pages = [1, 2, 3, 4, 5, '...', totalPages];
                      } else if (currentPage >= totalPages - 3) {
                        pages = [1, '...', totalPages - 4, totalPages - 3, totalPages - 2, totalPages - 1, totalPages];
                      } else {
                        pages = [1, '...', currentPage - 1, currentPage, currentPage + 1, '...', totalPages];
                      }
                    }

                    return pages.map((page, index) => {
                      if (page === '...') {
                        return (
                          <span key={`ellipsis-${index}`} className="flex h-10 w-10 items-center justify-center text-[15px] font-medium text-black">
                            ...
                          </span>
                        );
                      }
                      return (
                        <button
                          key={page}
                          onClick={() => {
                            setPage((page as number) - 1);
                            window.scrollTo({ top: 0, behavior: 'smooth' });
                          }}
                          className={`flex h-10 min-w-10 items-center justify-center rounded-xl px-2 text-[15px] transition-colors ${currentPage === page
                            ? 'bg-[#e6e6e6] font-semibold text-black'
                            : 'font-medium text-black hover:bg-black/5'
                            }`}
                        >
                          {page}
                        </button>
                      );
                    });
                  })()}
                </div>

                <button
                  disabled={currentPage === totalPages}
                  onClick={() => {
                    setPage(prev => prev + 1);
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                  }}
                  className="flex items-center justify-center text-black transition-opacity hover:opacity-60 disabled:opacity-20"
                  aria-label="Trang sau"
                >
                  <span className="material-symbols-outlined" style={{ fontSize: 24, strokeWidth: 1 }}>chevron_right</span>
                </button>
              </div>
            )}
          </div>
        </div>
      ) : (
        <div className="empty-catalog">
          <h2>{newArrivalsOnly ? "Chưa có sản phẩm mới" : "Chưa có sản phẩm phù hợp"}</h2>
          <p>{newArrivalsOnly ? "Hiện chưa có sản phẩm được tạo trong 7 ngày gần nhất." : "Hãy thử bỏ bớt bộ lọc hoặc tìm bằng từ khóa khác."}</p>
          {newArrivalsOnly ? <Link href="/products">Khám phá sản phẩm</Link> : <button onClick={() => { clearFilters(); setQuery(""); setCategoryId(null); }}>Xem tất cả sản phẩm</button>}
        </div>
      )}

      {!newArrivalsOnly && <FilterSidebar
        isOpen={filterOpen}
        onClose={() => setFilterOpen(false)}
        value={filters}
        onChange={(f) => { setFilters(f); setPage(0); }}
        resultCount={totalProducts}
        resultsLoading={productsLoading}
        selectedColorIds={selectedColorIds}
        selectedSizeIds={selectedSizeIds}
        onToggleColor={toggleColor}
        onToggleSize={toggleSize}
        onReset={clearFilters}
      />}
    </>
  );
}
