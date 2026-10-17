"use client";

import { useEffect, useState, useRef } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import {
  listPosts,
  loadPostJournal,
  isPostAbort,
  type JournalSection,
  postDate,
  type Post,
} from "@/service/postService";
import type { PageResponse } from "@/type/api";
import styles from "./blog.module.css";

export default function BlogPage() {
  const router = useRouter();
  const [categories, setCategories] = useState<JournalSection[]>([]);
  const [suggestions, setSuggestions] = useState<Post[]>([]);
  const [suggestionsError, setSuggestionsError] = useState<string | null>(null);
  const [allPosts, setAllPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [overviewError, setOverviewError] = useState<string | null>(null);
  const [categoryError, setCategoryError] = useState<string | null>(null);
  const [retry, setRetry] = useState(0);
  const [searchQuery, setSearchQuery] = useState("");
  const [query, setQuery] = useState("");
  const [activeCategoryId, setActiveCategoryId] = useState<number | null>(null);
  const [page, setPage] = useState(0);
  const [result, setResult] = useState<{ key: string; data: PageResponse<Post> | null; error: string | null } | null>(null);
  const isFiltering = Boolean(searchQuery.trim() || activeCategoryId !== null);
  const resultKey = JSON.stringify([query, activeCategoryId, page, retry]);
  const resultsLoading = query !== searchQuery.trim() || result?.key !== resultKey;
  const filteredPosts = result?.key === resultKey ? result.data?.content ?? [] : [];
  const filterError = result?.key === resultKey ? result.error : null;

  const railRef = useRef<HTMLDivElement>(null);

  // Cuộn thanh trượt danh mục trái / phải
  function scrollRail(direction: "left" | "right") {
    if (railRef.current) {
      const offset = direction === "left" ? -320 : 320;
      railRef.current.scrollBy({ left: offset, behavior: "smooth" });
    }
  }

  useEffect(() => {
    const controller = new AbortController();
    loadPostJournal(controller.signal).then(data => {
      if (controller.signal.aborted) return;
      setAllPosts(data.posts); setCategories(data.sections);
      setSuggestions(data.recommendations); setSuggestionsError(data.recommendationsError);
      setOverviewError(data.postsError); setCategoryError(data.categoriesError);
    }).catch(error => {
      if (!isPostAbort(error)) setOverviewError(error instanceof Error ? error.message : "Không tải được bài viết.");
    }).finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [retry]);

  useEffect(() => {
    const timer = setTimeout(() => { setQuery(searchQuery.trim()); setPage(0); }, 350);
    return () => clearTimeout(timer);
  }, [searchQuery]);

  useEffect(() => {
    if (!query && activeCategoryId === null) return;
    const controller = new AbortController();
    listPosts(query, activeCategoryId == null ? "" : String(activeCategoryId), page, 12, controller.signal)
      .then(data => { if (!controller.signal.aborted) setResult({ key: resultKey, data, error: null }); })
      .catch(error => { if (!controller.signal.aborted) setResult({ key: resultKey, data: null, error: error instanceof Error ? error.message : "Không tải được bài viết." }); });
    return () => controller.abort();
  }, [query, activeCategoryId, page, resultKey]);

  const featuredPost = allPosts[0] || null;
  const recommendedPosts = suggestions;
  const categoriesWithPosts = categories.filter(c => c.posts.length > 0 || c.error);
  const activeCategory = categories.find(c => c.id === activeCategoryId);
  function retryRequests() { setLoading(true); setOverviewError(null); setCategoryError(null); setRetry(value => value + 1); }

  // Chọn danh mục
  function handleSelectCategory(catId: number) {
    const category = categories.find(c => c.id === catId);
    if (category) router.push(`/blog/category/${encodeURIComponent(category.slug)}`);
  }

  // Xóa bộ lọc
  function handleResetFilters() {
    setSearchQuery("");
    setActiveCategoryId(null);
    setQuery(""); setPage(0);
  }

  return (
    <>
      <Header />
      <main className={styles.main}>
        {/* ==============================================================
            ẢNH 1: CAROUSEL DANH MỤC + THANH TÌM KIẾM BÀI VIẾT
            ============================================================== */}
        {categories.length > 0 && <section
          aria-label="Danh mục bài viết"
          className="relative px-2 sm:px-6 pt-4 pb-2"
        >
          {/* Nút lùi slide trái */}
          <button
            type="button"
            onClick={() => scrollRail("left")}
            className={`${styles.navButton} ${styles.navPrev}`}
            aria-label="Cuộn danh mục sang trái"
          >
            <span
              className="material-symbols-outlined"
              style={{ fontSize: 20 }}
            >
              chevron_left
            </span>
          </button>

          {/* Dải danh mục cuộn ngang */}
          <div
            ref={railRef}
            className={`flex items-start gap-4 sm:gap-6 overflow-x-auto scroll-smooth py-2 px-1 ${styles.noScrollbar}`}
          >
            {categories.map((cat) => {
              const isSelected = activeCategoryId === cat.id;
              return (
                <div
                  key={cat.id}
                  onClick={() => handleSelectCategory(cat.id)}
                  className={`${styles.categoryCard} group`}
                  role="button"
                  tabIndex={0}
                  aria-pressed={isSelected}
                  onKeyDown={e => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); handleSelectCategory(cat.id); } }}
                >
                  <div
                    className={`${styles.categoryImage} ${isSelected
                      ? "ring-2 ring-black ring-offset-2 scale-[1.02]"
                      : ""
                      }`}
                  >
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    {cat.image ? <img
                      src={cat.image}
                      alt={cat.name}
                      loading="lazy"
                      className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                    /> : <div className="w-full h-full bg-stone-100 flex items-center justify-center" aria-hidden="true"><span className="material-symbols-outlined text-stone-400">article</span></div>}
                  </div>
                  <h3
                    className={`mt-2.5 text-[16px] truncate text-center transition-all duration-200 ${isSelected
                      ? "font-normal text-gray-900"
                      : "font-medium text-gray-900 "
                      }`}
                  >
                    {cat.name}
                  </h3>
                </div>
              );
            })}
          </div>

          {/* Nút tiến slide phải */}
          <button
            type="button"
            onClick={() => scrollRail("right")}
            className={`${styles.navButton} ${styles.navNext}`}
            aria-label="Cuộn danh mục sang phải"
          >
            <span
              className="material-symbols-outlined"
              style={{ fontSize: 20 }}
            >
              chevron_right
            </span>
          </button>
        </section>}

        {/* Thanh tìm kiếm tròn ở giữa */}
        <div className={styles.searchWrapper}>
          <div className={styles.searchBar}>
            <span
              className="material-symbols-outlined text-[#8c8c84]"
              style={{ fontSize: 20 }}
            >
              search
            </span>
            <input
              type="search"
              maxLength={255}
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Tìm kiếm bài viết"
              className={styles.searchInput}
              aria-label="Tìm kiếm bài viết"
            />
            {searchQuery && (
              <button
                type="button"
                onClick={() => setSearchQuery("")}
                className="text-[#999] hover:text-black transition-colors"
                aria-label="Xóa từ khóa"
              >
                <span
                  className="material-symbols-outlined"
                  style={{ fontSize: 18 }}
                >
                  close
                </span>
              </button>
            )}
          </div>
        </div>

        {categoryError && <div role="alert" className="my-4 rounded-lg border border-amber-200 bg-amber-50 p-4 text-sm">{categoryError} <button type="button" className="underline ml-3" onClick={retryRequests}>Thử lại</button></div>}
        {overviewError && !isFiltering && <div role="alert" className="my-4 rounded-lg border border-red-100 bg-red-50 p-5">{overviewError} <button type="button" className="underline ml-3" onClick={retryRequests}>Thử lại</button></div>}
        {/* ==============================================================
            CHẾ ĐỘ LOADING SKELETON
            ============================================================== */}
        {(isFiltering ? resultsLoading : loading) ? (
          <div className="space-y-10 animate-pulse py-6">
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
              <div className="lg:col-span-7">
                <div className="h-8 bg-gray-200 rounded w-48 mb-5" />
                <div className="aspect-[16/10] bg-gray-200 rounded-2xl w-full" />
                <div className="h-4 bg-gray-200 rounded w-1/3 mt-4" />
                <div className="h-6 bg-gray-200 rounded w-4/5 mt-2" />
              </div>
              <div className="lg:col-span-5 flex flex-col justify-between">
                <div className="h-8 bg-gray-200 rounded w-40 mb-5" />
                <div className="space-y-5">
                  {[1, 2, 3, 4].map((i) => (
                    <div key={i} className="flex gap-4 items-center">
                      <div className="w-36 h-24 sm:w-44 sm:h-28 bg-gray-200 rounded-xl shrink-0" />
                      <div className="flex-1 space-y-2">
                        <div className="h-3 bg-gray-200 rounded w-1/2" />
                        <div className="h-4 bg-gray-200 rounded w-4/5" />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        ) : isFiltering ? (
          <section className="mt-4 mb-16">
            <div className="flex flex-wrap items-center justify-between gap-4 border-b border-gray-200 pb-4 mb-8">
              <div>
                <h2 className="text-xl sm:text-2xl font-bold text-gray-900">
                  {searchQuery
                    ? `Kết quả tìm kiếm cho: “${searchQuery}”`
                    : `Danh mục: ${activeCategory?.name || "Tất cả"}`}
                </h2>
                <p className="text-sm text-gray-500 mt-1">
                  Tìm thấy {result?.data?.totalElements ?? 0} bài viết
                </p>
              </div>
              <button
                type="button"
                onClick={handleResetFilters}
                className={styles.seeMoreBtn}
              >
                <span
                  className="material-symbols-outlined"
                  style={{ fontSize: 16 }}
                >
                  arrow_back
                </span>
                Xem tất cả bài viết
              </button>
            </div>

            {filterError ? <div role="alert" className="rounded-xl border border-red-100 bg-red-50 p-6">{filterError} <button type="button" onClick={retryRequests} className="underline ml-3">Thử lại</button></div> : filteredPosts.length === 0 ? (
              <div className="text-center py-20 bg-gray-50 rounded-2xl border border-gray-100">
                <span
                  className="material-symbols-outlined text-gray-400"
                  style={{ fontSize: 48 }}
                >
                  search_off
                </span>
                <p className="text-gray-700 text-base font-medium mt-3">
                  Không tìm thấy bài viết nào phù hợp.
                </p>
                <button
                  type="button"
                  onClick={handleResetFilters}
                  className="mt-4 inline-flex items-center gap-2 px-5 py-2 rounded-full bg-black text-white text-sm font-medium hover:bg-gray-800 transition-colors"
                >
                  Quay lại danh sách bài viết
                </button>
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 sm:gap-8">
                {filteredPosts.map((post) => (
                  <article key={post.id} className="group">
                    <Link
                      href={`/blog/${post.slug}`}
                      className="block overflow-hidden"
                    >
                      <div className={styles.cardImgWrapper}>
                        <div className="aspect-[4/3] w-full">
                          {/* eslint-disable-next-line @next/next/no-img-element */}
                          <img
                            src={post.thumbnail}
                            alt={post.title}
                            loading="lazy"
                            className={styles.cardImg}
                          />
                        </div>
                      </div>
                      <div className="text-xs text-gray-500 mt-3 font-medium">
                        {post.categoryName} • Ngày đăng:{" "}
                        {postDate(post.publishedAt)}
                      </div>
                      <h3 className="font-bold text-base text-gray-900 line-clamp-2 mt-1.5 group-hover:text-black leading-snug transition-colors">
                        {post.title}
                      </h3>
                      {post.summary && (
                        <p className="text-xs sm:text-sm text-gray-600 line-clamp-2 mt-1.5 leading-relaxed">
                          {post.summary}
                        </p>
                      )}
                    </Link>
                  </article>
                ))}
              </div>
            )}
            {!!result?.data && result.data.totalPages > 1 && <nav aria-label="Phân trang bài viết" className="flex items-center justify-center gap-5 mt-10">
              <button type="button" disabled={page === 0} onClick={() => setPage(p => p - 1)} className="border rounded-lg px-4 py-2 disabled:opacity-40">← Trang trước</button>
              <span>Trang {page + 1} / {result.data.totalPages}</span>
              <button type="button" disabled={page + 1 >= result.data.totalPages} onClick={() => setPage(p => p + 1)} className="border rounded-lg px-4 py-2 disabled:opacity-40">Trang sau →</button>
            </nav>}
          </section>
        ) : (
          /* ==============================================================
             CHẾ ĐỘ MẶC ĐỊNH (THEO ĐÚNG ẢNH 2 & ẢNH 3)
             ============================================================== */
          <>
            {!overviewError && !featuredPost && <div role="status" className="text-center py-16 bg-stone-50 rounded-xl mb-10"><h2 className="text-xl font-semibold">Chưa có bài viết được xuất bản</h2><p className="text-stone-500 mt-2">Ghé lại sau để đọc những câu chuyện mới từ Zella.</p></div>}
            {/* ẢNH 2: BÀI VIẾT MỚI NHẤT (BÊN TRÁI) + ĐỀ XUẤT CHO BẠN (BÊN PHẢI) */}
            {featuredPost && <section className="mb-14">
              <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 lg:gap-10">
                {/* CỘT TRÁI: BÀI VIẾT MỚI NHẤT */}
                <div className="lg:col-span-7">
                  <h2 className="text-2xl font-bold text-gray-900 mb-5">
                    Bài viết mới nhất
                  </h2>
                  {featuredPost && (
                    <article className="group cursor-pointer">
                      <Link
                        href={`/blog/${featuredPost.slug}`}
                        className="block"
                      >
                        <div className={styles.cardImgWrapper}>
                          <div className="aspect-[16/10] w-full">
                            {/* eslint-disable-next-line @next/next/no-img-element */}
                            <img
                              src={featuredPost.thumbnail}
                              alt={featuredPost.title}
                              className={styles.cardImg}
                            />
                          </div>
                        </div>
                        <div className="normal-caption pt-2 ">
                          {featuredPost.categoryName} • Ngày đăng:{" "}
                          {postDate(featuredPost.publishedAt)}
                        </div>
                        <h3 className="text-xl sm:text-2xl font-bold text-gray-900 mt-2 line-clamp-2 group-hover:text-black leading-snug transition-colors">
                          {featuredPost.title}
                        </h3>
                        {featuredPost.summary && (
                          <p className="normal-caption sm:text-base  line-clamp-3 mt-2 leading-relaxed">
                            {featuredPost.summary}
                          </p>
                        )}
                      </Link>
                    </article>
                  )}
                </div>

                {/* CỘT PHẢI: ĐỀ XUẤT CHO BẠN */}
                <div className="lg:col-span-5 flex flex-col">
                  <h2 className="text-2xl font-bold text-gray-900 mb-5">
                    Đề xuất cho bạn
                  </h2>
                  <div className="flex flex-col gap-5 justify-between flex-1">
                    {suggestionsError && <p role="alert" className="text-sm text-red-700">{suggestionsError} <button type="button" onClick={retryRequests} className="underline">Thử lại</button></p>}
                    {!suggestionsError && !recommendedPosts.length && <p className="text-sm text-stone-500">Chưa có bài viết khác để đề xuất.</p>}
                    {recommendedPosts.map((post) => (
                      <article key={post.id} className="group">
                        <Link
                          href={`/blog/${post.slug}`}
                          className="flex gap-4 items-center"
                        >
                          <div className="w-36 h-24 sm:w-44 sm:h-28 rounded-xl overflow-hidden shrink-0 relative bg-gray-100">
                            {/* eslint-disable-next-line @next/next/no-img-element */}
                            <img
                              src={post.thumbnail}
                              alt={post.title}
                              loading="lazy"
                              className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
                            />
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="normal-caption">
                              {post.categoryName} • Ngày đăng:{" "}
                              {postDate(post.publishedAt)}
                            </div>
                            <h3 className=" sm:text-base text-[18px]  line-clamp-2 mt-1 leading-snug transition-colors normal-title">
                              {post.title}
                            </h3>
                          </div>
                        </Link>
                      </article>
                    ))}
                  </div>
                </div>
              </div>
            </section>}

            {/* ==============================================================
                ẢNH 3: TIÊU ĐỀ LÀ TÊN CATEGORIES, PHÍA DƯỚI LÀ BÀI VIẾT THUỘC DANH MỤC
                ============================================================== */}
            <div className="space-y-14 pt-4 border-t border-gray-100">
              {categoriesWithPosts.map((catSection) => (
                <section key={catSection.id} className="pt-2">
                  {/* Tiêu đề danh mục + Nút Xem thêm */}
                  <div className="flex items-center justify-between gap-4 mb-5">
                    <h2 className="text-2xl sm:text-[26px] font-bold text-gray-900">
                      {catSection.name}
                    </h2>
                    <button
                      type="button"
                      onClick={() => handleSelectCategory(catSection.id)}
                      className={styles.seeMoreBtn}
                      aria-label={`Xem thêm bài viết thuộc danh mục ${catSection.name}`}
                    >
                      Xem thêm
                    </button>
                  </div>

                  {/* Lưới 3 bài viết thuộc danh mục */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 sm:gap-7">
                    {catSection.error && <div role="alert" className="col-span-full text-sm text-red-700">{catSection.error} <button className="underline ml-2" onClick={retryRequests}>Thử lại</button></div>}
                    {catSection.posts.slice(0, 3).map((post) => (
                      <article key={post.id} className="group">
                        <Link
                          href={`/blog/${post.slug}`}
                          className="block overflow-hidden"
                        >
                          <div className={styles.cardImgWrapper}>
                            <div className="aspect-[4/3] w-full">
                              {/* eslint-disable-next-line @next/next/no-img-element */}
                              <img
                                src={post.thumbnail}
                                alt={post.title}
                                loading="lazy"
                                className={styles.cardImg}
                              />
                            </div>
                          </div>
                          <div className="text-xs text-gray-500 mt-3 font-medium">
                            Ngày đăng: {postDate(post.publishedAt)}
                          </div>
                          <h3 className="font-bold text-base text-gray-900 line-clamp-2 mt-1.5 group-hover:text-black leading-snug transition-colors">
                            {post.title}
                          </h3>
                        </Link>
                      </article>
                    ))}
                  </div>
                </section>
              ))}
            </div>
          </>
        )}
      </main>
      <Footer />
    </>
  );
}
