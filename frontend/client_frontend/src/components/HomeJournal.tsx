"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { popularPosts, type PopularPost } from "@/service/postService";
import styles from "./HomeJournal.module.css";
import ConnectionError from "./ConnectionError";

export default function HomeJournal() {
  const [post, setPost] = useState<PopularPost | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [retry, setRetry] = useState(0);

  useEffect(() => {
    const controller = new AbortController();
    popularPosts(controller.signal)
      .then(data => {
        if (!controller.signal.aborted) setPost(data[0] ?? null);
      })
      .catch(reason => {
        if (!controller.signal.aborted) setError(reason instanceof Error ? reason.message : "Không tải được bài viết.");
      })
      .finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [retry]);

  if (loading) return <section className={styles.section} aria-label="Bài viết nổi bật" aria-busy="true">
    <div className={`${styles.bannerLink} ${styles.skeleton}`} role="status" aria-label="Đang tải bài viết được xem nhiều nhất">
      <div className={styles.overlay} aria-hidden="true">
        <div className={`container mx-auto ${styles.overlayContent}`}>
          <div className={`${styles.skeletonLine} ${styles.skeletonMeta}`} />
          <div className={`${styles.skeletonLine} ${styles.skeletonTitle}`} />
          <div className={`${styles.skeletonLine} ${styles.skeletonSummary}`} />
        </div>
      </div>
    </div>
  </section>;
  if (error) return <ConnectionError onRetry={() => { setError(null); setLoading(true); setRetry(n => n + 1); }} />;
  if (!post) return null;

  return (
    <section className={styles.section} aria-label="Bài viết nổi bật">
      <div className={styles.bannerLink}>
        <Link href={`/blog/${post.slug}`} className={styles.articleLink}>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={post.thumbnail}
            alt={post.title}
            loading="lazy"
            className={styles.bannerImage}
          />
        </Link>
        <div className={styles.scrim} aria-hidden="true" />
        <div className={styles.overlay}>
          <div className={`container mx-auto ${styles.overlayContent}`}>
            <p className={styles.meta}>{post.categoryName}</p>
            <h2 className={styles.title}>{post.title}</h2>
            {post.summary && <p className={styles.summary}>{post.summary}</p>}
            <Link href="/blog" className={styles.allPostsButton}>Tất cả bài viết <span aria-hidden="true">↗</span></Link>
          </div>
        </div>
      </div>
    </section>
  );
}
