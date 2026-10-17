"use client";
import { useEffect, useState } from "react";
import BlogCard from "./BlogCard";
import { listPosts, postDate, type Post } from "@/service/postService";
export default function BlogCardSection() {
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [retry, setRetry] = useState(0);
  useEffect(() => {
    const controller = new AbortController();
    listPosts("", "", 0, 3, controller.signal).then(p => { if (!controller.signal.aborted) setPosts(p.content); })
      .catch(e => { if (!controller.signal.aborted) setError(e instanceof Error ? e.message : "Chưa tải được bài viết."); })
      .finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [retry]);
  if (loading) return <div className="blog-card-grid" role="status" aria-label="Đang tải bài viết">{[0,1,2].map(n => <div key={n} className="h-72 rounded-xl bg-stone-100 animate-pulse" aria-hidden="true" />)}</div>;
  if (error) return <div role="alert">{error} <button className="underline ml-3" onClick={() => { setLoading(true); setError(""); setRetry(n => n + 1); }}>Thử lại</button></div>;
  if (!posts.length) return <p className="text-center text-stone-500 py-8">Những câu chuyện mới từ Zella đang được chuẩn bị.</p>;
  return <div className="blog-card-grid">{posts.map(p => <BlogCard key={p.id} title={p.title} image={p.thumbnail} date={postDate(p.publishedAt)} category={p.categoryName} description={p.summary ?? ""} href={`/blog/${p.slug}`} />)}</div>;
}
