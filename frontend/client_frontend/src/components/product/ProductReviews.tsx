"use client";
import StarRating from "@/components/ui/StarRating";

import { useEffect, useState } from "react";
import { apiRequest } from "@/api/apiClient";
import type { ApiResponse, PageResponse } from "@/type/api";
import { apiError, displayDate } from "@/service/accountService";

export type ProductReview = { id: number; customerName: string; rating: number; comment?: string | null; colorName?: string | null; sizeName?: string | null; createdAt?: string | null; adminReply?: string | null };
export default function ProductReviews({ productId, initial, average, count }: { productId: number; initial: PageResponse<ProductReview>; average: number; count: number }) {
  const [page, setPage] = useState(0); const [retry, setRetry] = useState(0);
  const [result, setResult] = useState<{ page: number; data?: PageResponse<ProductReview>; error?: string; retry: number } | null>(null);
  useEffect(() => {
    const controller = new AbortController();
    if (page === 0 && retry === 0) return () => controller.abort();
    apiRequest(`/product/${productId}/reviews?page=${page}&size=20`, { signal: controller.signal }).then((response: ApiResponse<PageResponse<ProductReview>>) => {
      if (!controller.signal.aborted) setResult({ page, data: response.data, retry });
    }).catch(error => { if (!controller.signal.aborted) setResult({ page, error: apiError(error), retry }); });
    return () => controller.abort();
  }, [productId, page, retry]);
  const state = result?.page === page && result.retry === retry ? result : null;
  const data = page === 0 && retry === 0 ? initial : state?.data;
  const loading = !data && !state?.error;
  return <section id="reviews" className="reviews-section"><div className="reviews-section-header"><div><p className="subtext">Phản hồi thực tế</p><h2>Đánh giá từ khách hàng</h2></div>
    <div className="reviews-rating-summary"><div className="rating-num">{average.toFixed(1)}</div><div className="rating-stars"><StarRating rating={average} /></div><div className="rating-count">{count} đánh giá</div></div></div>
    {loading ? <div className="h-48 animate-pulse bg-gray-100 rounded" aria-label="Đang tải đánh giá" /> : state?.error ? <p role="alert">{state.error}<button className="underline ml-3" onClick={() => setRetry(value => value + 1)}>Thử lại</button></p>
      : <div className="reviews-list">{data?.content.map(review => <article key={review.id} className="review-item"><div className="review-header"><div className="review-avatar">{review.customerName.charAt(0)}</div><div><div className="review-name">{review.customerName}</div>
        <div className="review-meta">{[review.createdAt ? displayDate(review.createdAt) : null, review.sizeName ? `Size ${review.sizeName}` : null, review.colorName].filter(Boolean).join(" · ")}</div></div>
        <div className="review-stars"><StarRating rating={review.rating} /></div></div>{review.comment && <p className="review-text">{review.comment}</p>}
        {review.adminReply && <div className="review-text mt-3"><strong>Phản hồi từ ZELLA</strong><p>{review.adminReply}</p></div>}</article>)}</div>}
    {initial.totalPages > 1 && <nav aria-label="Phân trang đánh giá" className="flex justify-end items-center gap-4 mt-4 text-xs"><button disabled={loading || page === 0} className="border rounded px-3 py-2 disabled:opacity-40" onClick={() => setPage(value => value - 1)}>Trước</button>
      <span>{page + 1} / {data?.totalPages ?? initial.totalPages}</span><button disabled={loading || page + 1 >= (data?.totalPages ?? initial.totalPages)} className="border rounded px-3 py-2 disabled:opacity-40" onClick={() => setPage(value => value + 1)}>Sau</button></nav>}
  </section>;
}
