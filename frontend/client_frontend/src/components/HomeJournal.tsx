"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { popularPosts, type PopularPost } from "@/service/postService";
import styles from "./HomeJournal.module.css";
import { reportConnectionFailure } from "@/api/apiClient";
import { useHomeSectionReady } from "./HomeScrollReveal";

export default function HomeJournal() {
  const ready = useHomeSectionReady();
  const [post, setPost] = useState<PopularPost | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!ready) return;
    const controller = new AbortController();
    popularPosts(controller.signal)
      .then(data => {
        if (!controller.signal.aborted) setPost(data[0] ?? null);
      })
      .catch(() => {
        if (!controller.signal.aborted) reportConnectionFailure();
      })
      .finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [ready]);

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
