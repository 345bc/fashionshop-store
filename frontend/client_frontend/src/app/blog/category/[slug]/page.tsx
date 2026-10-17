"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import { postCategories, listPosts, recommendedPosts, postDate, isPostAbort, type Post, type PostCategory } from "@/service/postService";
import type { PageResponse } from "@/type/api";
import styles from "../../blog.module.css";
import categoryStyles from "./page.module.css";

export default function CategoryPage() {
  const { slug } = useParams<{ slug: string }>();
  return <><Header /><Category key={slug} slug={slug} /><Footer /></>;
}

function Cover({ post }: { post: Post }) {
  if (!post.thumbnail) {
    return (
      <div className="w-full h-full bg-stone-100 flex items-center justify-center text-stone-400">
        <span className="material-symbols-outlined" style={{ fontSize: 32 }}>image</span>
      </div>
    );
  }
  // eslint-disable-next-line @next/next/no-img-element
  return <img src={post.thumbnail} alt={post.title} className={styles.cardImg} loading="lazy" />;
}

function Category({ slug }: { slug: string }) {
  const [category, setCategory] = useState<PostCategory | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [latest, setLatest] = useState<Post | null>(null);
  const [suggestions, setSuggestions] = useState<Post[]>([]);
  const [suggestionsError, setSuggestionsError] = useState<string | null>(null);
  const [latestError, setLatestError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(0);
  const [retry, setRetry] = useState(0);
  const [result, setResult] = useState<{ key: string; data?: PageResponse<Post>; error?: string } | null>(null);
  const resultKey = JSON.stringify([category?.id, query, page, retry]);
  const waiting = result?.key !== resultKey || search.trim() !== query;
  const current = result?.key === resultKey ? result : null;
  const refresh = () => setRetry(value => value + 1);

  useEffect(() => {
    const controller = new AbortController();
    postCategories(controller.signal).then(async categories => {
      const selected = categories.find(c => c.slug === slug);
      if (!selected) throw new Error("Danh mục không tồn tại hoặc đã được ẩn.");
      if (controller.signal.aborted) return;
      setCategory(selected);
      const [newest, proposed] = await Promise.allSettled([
        listPosts("", String(selected.id), 0, 1, controller.signal),
        recommendedPosts(controller.signal, selected.id),
      ]);
      if (controller.signal.aborted) return;
      setLatest(newest.status === "fulfilled" ? newest.value.content[0] ?? null : null);
      setLatestError(newest.status === "rejected" ? newest.reason.message : null);
      setSuggestions(proposed.status === "fulfilled" ? proposed.value : []);
      setSuggestionsError(proposed.status === "rejected" ? proposed.reason.message : null);
      setError(null);
    }).catch(reason => {
      if (!isPostAbort(reason) && !controller.signal.aborted) setError(reason.message);
    }).finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [slug, retry]);

  useEffect(() => {
    const timer = setTimeout(() => { setQuery(search.trim()); setPage(0); }, 350);
    return () => clearTimeout(timer);
  }, [search]);

  useEffect(() => {
    if (!category) return;
    const controller = new AbortController();
    listPosts(query, String(category.id), page, 12, controller.signal)
      .then(data => { if (!controller.signal.aborted) setResult({ key: resultKey, data }); })
      .catch(reason => { if (!controller.signal.aborted) setResult({ key: resultKey, error: reason.message }); });
    return () => controller.abort();
  }, [category, query, page, resultKey]);

  const failure = (message: string) => <p role="alert" className={categoryStyles.message}>{message} <button onClick={refresh} className="underline ml-3">Thử lại</button></p>;

  if (error) {
    return (
      <main className={`container mx-auto ${categoryStyles.main}`}>
        {failure(error)}
      </main>
    );
  }

  return (
    <>
      <h1 className="sr-only">{category?.name ?? "Danh mục bài viết"}</h1>

      {/* HERO SECTION: Ảnh to tràn viền 100vw ngoài container + Thanh tìm kiếm sát đáy màn hình */}
      <section className={categoryStyles.hero}>
        {category?.thumbnail ? (
          <div className={categoryStyles.banner}>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={category.thumbnail} alt={category.name} fetchPriority="high" />
          </div>
        ) : loading ? (
          <div className={`${categoryStyles.banner} animate-pulse bg-gray-200`} />
        ) : null}
        <div className={`${styles.searchWrapper} ${categoryStyles.search}`}>
          <div className={styles.searchBar}>
            <span className="material-symbols-outlined" aria-hidden="true">search</span>
            <input
              type="search"
              maxLength={255}
              className={styles.searchInput}
              placeholder="Tìm kiếm bài viết"
              aria-label={`Tìm bài viết trong ${category?.name ?? "danh mục"}`}
              value={search}
              onChange={e => setSearch(e.target.value)}
            />
            {search && (
              <button
                type="button"
                onClick={() => setSearch("")}
                className="text-[#999] hover:text-black transition-colors"
                aria-label="Xóa từ khóa"
              >
                <span className="material-symbols-outlined" style={{ fontSize: 18 }}>
                  close
                </span>
              </button>
            )}
          </div>
        </div>
      </section>

      {/* PHẦN NỘI DUNG: Đặt trong container */}
      <main className={`container mx-auto ${categoryStyles.main}`}>
        {loading ? (
          <div className="space-y-10 animate-pulse py-6">
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
              <div className="lg:col-span-7">
                <div className="h-8 bg-gray-200 rounded w-48 mb-5" />
                <div className="aspect-[16/10] bg-gray-200 rounded-2xl w-full" />
                <div className="h-4 bg-gray-200 rounded w-1/3 mt-4" />
                <div className="h-6 bg-gray-200 rounded w-4/5 mt-2" />
                <div className="h-4 bg-gray-200 rounded w-full mt-3" />
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
        ) : (
          <>
            {!search.trim() && (
              <section className={categoryStyles.overview}>
                <div>
                  <h2>Bài viết mới nhất</h2>
                  {latestError ? failure(latestError) : latest ? (
                    <article>
                      <Link href={`/blog/${latest.slug}`}>
                        <div className={`${styles.cardImgWrapper} ${categoryStyles.featureImage}`}><Cover post={latest} /></div>
                        <p className="normal-caption pt-2">{latest.categoryName} · Ngày đăng: {postDate(latest.publishedAt)}</p>
                        <h3 className="text-xl sm:text-2xl font-bold text-gray-900 mt-2 line-clamp-2 group-hover:text-black leading-snug transition-colors">{latest.title}</h3>
                        {latest.summary && <p className="normal-caption sm:text-base line-clamp-3 mt-2 leading-relaxed">{latest.summary}</p>}
                      </Link>
                    </article>
                  ) : <p className={categoryStyles.message}>Danh mục chưa có bài viết.</p>}
                </div>
                <div>
                  <h2>Đề xuất cho bạn</h2>
                  {suggestionsError ? failure(suggestionsError) : suggestions.length ? (
                    <div className={categoryStyles.suggestions}>
                      {suggestions.map(post => (
                        <article key={post.id}>
                          <Link href={`/blog/${post.slug}`} className={categoryStyles.suggestion}>
                            <div className={`${styles.cardImgWrapper} ${categoryStyles.suggestionImage}`}><Cover post={post} /></div>
                            <div>
                              <p className="normal-caption">{post.categoryName} · Ngày đăng: {postDate(post.publishedAt)}</p>
                              <h3 className="sm:text-base text-[18px] line-clamp-2 mt-1 leading-snug transition-colors normal-title !mb-0">{post.title}</h3>
                            </div>
                          </Link>
                        </article>
                      ))}
                    </div>
                  ) : <p className={categoryStyles.message}>Chưa có bài viết khác để đề xuất.</p>}
                </div>
              </section>
            )}
            <section className={categoryStyles.allPosts}>
              <h2>{search.trim() ? `Kết quả tìm kiếm: “${search.trim()}”` : "Tất cả bài viết"}</h2>
              {waiting ? (
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 animate-pulse py-4">
                  {[1, 2, 3, 4, 5, 6].map((i) => (
                    <div key={i} className="space-y-3">
                      <div className="aspect-[16/10] bg-gray-200 rounded-xl w-full" />
                      <div className="h-3 bg-gray-200 rounded w-1/3" />
                      <div className="h-5 bg-gray-200 rounded w-4/5" />
                    </div>
                  ))}
                </div>
              ) : current?.error ? (
                failure(current.error)
              ) : current?.data?.content.length ? (
                <>
                  <div className={categoryStyles.grid}>
                    {current.data.content.map(post => (
                      <article key={post.id}>
                        <Link href={`/blog/${post.slug}`}>
                          <div className={`${styles.cardImgWrapper} ${categoryStyles.gridImage}`}><Cover post={post} /></div>
                          <p className="normal-caption pt-2">Ngày đăng: {postDate(post.publishedAt)}</p>
                          <h3 className="sm:text-base text-[18px] line-clamp-2 mt-1 leading-snug transition-colors normal-title !mb-0">{post.title}</h3>
                        </Link>
                      </article>
                    ))}
                  </div>
                  {current.data.totalPages > 1 && (
                    <nav aria-label="Phân trang bài viết" className={categoryStyles.pagination}>
                      <button disabled={page === 0} onClick={() => setPage(p => p - 1)}>← Trang trước</button>
                      <span>Trang {page + 1} / {current.data.totalPages}</span>
                      <button disabled={page + 1 >= current.data.totalPages} onClick={() => setPage(p => p + 1)}>Trang sau →</button>
                    </nav>
                  )}
                </>
              ) : (
                <p className={categoryStyles.message}>{search.trim() ? "Không tìm thấy bài viết phù hợp trong danh mục này." : "Danh mục chưa có bài viết."}</p>
              )}
            </section>
          </>
        )}
      </main>
    </>
  );
}
