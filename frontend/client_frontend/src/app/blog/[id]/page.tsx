"use client";

import { useEffect, useState, type FormEvent } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import { trackPostView } from "@/service/postViewTracker";
import PostContent from "@/components/PostContent";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import { readPost, listPosts, popularPosts, postDate, PostRequestError, type Post } from "@/service/postService";
import styles from "./article.module.css";

type SidebarPost = Pick<Post, "id" | "slug" | "thumbnail" | "title" | "categoryName" | "publishedAt">;

export default function ArticleDetailPage() {
  const { id } = useParams<{ id: string }>();
  return <Article key={id} id={id} />;
}

function Article({ id }: { id: string }) {
  const [post, setPost] = useState<Post | null>(null);
  const [error, setError] = useState("");
  const [notFound, setNotFound] = useState(false);
  const [retry, setRetry] = useState(0);
  const [copyStatus, setCopyStatus] = useState("");
  useEffect(() => {
    const controller = new AbortController();
    readPost(id, controller.signal).then(data => { if (!controller.signal.aborted) setPost(data); })
      .catch(reason => {
        if (controller.signal.aborted) return;
        setError(reason instanceof Error ? reason.message : "Không tải được bài viết.");
        setNotFound(reason instanceof PostRequestError && reason.status === 404);
      });
    return () => controller.abort();
  }, [id, retry]);
  const loadedSlug = post?.slug;
  useEffect(() => {
    if (!loadedSlug) return;
    return trackPostView(loadedSlug, views => setPost(current => current?.slug === loadedSlug ? { ...current, viewCount: views } : current));
  }, [loadedSlug]);
  async function copyLink() {
    try { await navigator.clipboard.writeText(window.location.href); setCopyStatus("Đã sao chép liên kết"); }
    catch { setCopyStatus("Bạn có thể sao chép địa chỉ trên thanh trình duyệt."); }
  }
  return <><Header /><main className={styles.main} aria-busy={!post && !error}>
    <div className={`container mx-auto ${styles.container}`}>
      {error ? <section className={styles.error} role="alert">
        <h1>{notFound ? "Không tìm thấy bài viết" : "Chưa tải được bài viết"}</h1><p>{error}</p>
        <Link href="/blog">← Tất cả bài viết</Link>
        {!notFound && <button type="button" onClick={() => { setError(""); setNotFound(false); setPost(null); setRetry(n => n + 1); }}>Thử lại</button>}
      </section> : !post ? <ArticleSkeleton /> : <div className={styles.layout}>
        <article className={styles.article}>
          <header className={styles.articleHeader}>
            <h1 className={styles.title}>{post.title}</h1>
            <div className={styles.meta}><span>{post.categoryName}</span><span aria-hidden="true">•</span>
              <span>Ngày đăng: <time dateTime={post.publishedAt}>{postDate(post.publishedAt)}</time></span>
            </div>
          </header>
          <figure className={styles.cover}>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={post.thumbnail} alt={post.title} fetchPriority="high" />
          </figure>
          {post.summary && <p className={styles.summary}>{post.summary}</p>}
          <PostContent content={post.content ?? ""} />
          <footer className={styles.articleFooter}>
            <div className={styles.footerActions}>
              <Link href="/blog">← Tất cả bài viết</Link>
              <button type="button" onClick={copyLink}><span className="material-symbols-outlined" aria-hidden="true">link</span> Sao chép liên kết</button>
            </div><p className={styles.copyStatus} role="status">{copyStatus}</p>
          </footer>
        </article>
        <ArticleSidebar currentSlug={post.slug} />
      </div>}
    </div>
  </main><Footer /></>;
}

function ArticleSidebar({ currentSlug }: { currentSlug: string }) {
  const [popular, setPopular] = useState<SidebarPost[]>([]);
  const [latest, setLatest] = useState<SidebarPost[]>([]);
  const [loading, setLoading] = useState(true);
  const [popularError, setPopularError] = useState(false);
  const [latestError, setLatestError] = useState(false);
  const [retry, setRetry] = useState(0);
  const [input, setInput] = useState("");
  const [query, setQuery] = useState("");
  const [search, setSearch] = useState<{ query: string; posts: SidebarPost[]; total: number; error: boolean } | null>(null);
  const [searchRetry, setSearchRetry] = useState(0);
  useEffect(() => {
    const controller = new AbortController();
    Promise.allSettled([popularPosts(controller.signal, 4), listPosts("", "", 0, 4, controller.signal)])
      .then(([popularResult, latestResult]) => {
        if (controller.signal.aborted) return;
        if (popularResult.status === "fulfilled") setPopular(popularResult.value.filter(post => post.slug !== currentSlug).slice(0, 3));
        else setPopularError(true);
        if (latestResult.status === "fulfilled") setLatest(latestResult.value.content.filter(post => post.slug !== currentSlug).slice(0, 3));
        else setLatestError(true);
        setLoading(false);
      });
    return () => controller.abort();
  }, [currentSlug, retry]);
  useEffect(() => {
    if (!query) return;
    const controller = new AbortController();
    listPosts(query, "", 0, 5, controller.signal)
      .then(data => { if (!controller.signal.aborted) setSearch({ query, posts: data.content, total: data.totalElements, error: false }); })
      .catch(() => { if (!controller.signal.aborted) setSearch({ query, posts: [], total: 0, error: true }); });
    return () => controller.abort();
  }, [query, searchRetry]);
  function submit(event: FormEvent<HTMLFormElement>) { event.preventDefault(); setQuery(input.trim()); setSearch(null); setSearchRetry(n => n + 1); }
  function reload() { setPopularError(false); setLatestError(false); setLoading(true); setRetry(n => n + 1); }
  const searching = Boolean(query && search?.query !== query);
  return <aside className={styles.aside} aria-label="Tìm kiếm và khám phá bài viết">
    <form className={styles.searchForm} role="search" onSubmit={submit}>
      <label htmlFor="article-search" className="sr-only">Tìm kiếm bài viết</label>
      <input id="article-search" value={input} onChange={event => setInput(event.target.value)} placeholder="Tìm kiếm bài viết" maxLength={255} />
      <button type="submit" aria-label="Tìm kiếm"><span className="material-symbols-outlined" aria-hidden="true">search</span></button>
    </form>
    {query ? <section className={styles.sideSection} aria-live="polite">
      <div className={styles.searchHeading}><h2>Kết quả tìm kiếm</h2><button type="button" onClick={() => { setInput(""); setQuery(""); setSearch(null); }}>Xóa</button></div>
      {searching ? <SideSkeleton /> : search?.error ? <SideError onRetry={() => { setSearch(null); setSearchRetry(n => n + 1); }} /> : <>
        <p className={styles.searchCount}>{search?.total ?? 0} kết quả cho “{query}”</p>
        <SideList posts={search?.posts ?? []} />
      </>}
    </section> : <>
      {(loading || popularError || popular.length > 0) && <section className={styles.sideSection}>
        <h2>Bài đọc nhiều nhất</h2>
        {loading ? <SideSkeleton /> : popularError ? <SideError onRetry={reload} /> : <SideList posts={popular} ranked />}
      </section>}
      {(loading || latestError || latest.length > 0) && <section className={styles.sideSection}>
        <h2>Bài viết mới nhất</h2>
        {loading ? <SideSkeleton /> : latestError ? <SideError onRetry={reload} /> : <SideList posts={latest} />}
      </section>}
    </>}
  </aside>;
}

function SideList({ posts, ranked = false }: { posts: SidebarPost[]; ranked?: boolean }) {
  return <div className={styles.sideList}>{posts.map((post, index) => <Link key={post.id} href={`/blog/${post.slug}`} className={styles.sideCard}>
    {/* eslint-disable-next-line @next/next/no-img-element */}
    <img src={post.thumbnail} alt={post.title} loading="lazy" />
    <div className={styles.sideCopy}>
      {ranked && <span className={styles.rank}>{index + 1}</span>}
      <time dateTime={post.publishedAt}>{postDate(post.publishedAt)}</time>
      <p className={styles.sideCategory}>{post.categoryName}</p>
      <h3>{post.title}</h3>
    </div>
  </Link>)}</div>;
}
function SideSkeleton() { return <div aria-label="Đang tải bài viết">{[1, 2, 3].map(item => <div key={item} className={`${styles.sideSkeleton} ${styles.shimmer}`} />)}</div>; }
function SideError({ onRetry }: { onRetry: () => void }) { return <div className={styles.sideError} role="alert"><p>Chưa tải được bài viết.</p><button type="button" onClick={onRetry}>Thử lại</button></div>; }
function ArticleSkeleton() {
  return <div className={styles.layout} role="status" aria-label="Đang tải bài viết"><span className="sr-only">Đang tải bài viết…</span>
    <div aria-hidden="true"><div className={`${styles.skeletonTitle} ${styles.shimmer}`} /><div className={`${styles.skeletonMeta} ${styles.shimmer}`} /><div className={`${styles.skeletonCover} ${styles.shimmer}`} /></div>
    <div aria-hidden="true"><SideSkeleton /></div>
  </div>;
}
