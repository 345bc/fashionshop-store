import { apiRequest, ApiClientError, reportConnectionFailure } from "@/api/apiClient";
import type { PageResponse } from "@/type/api";

export type PostCategory = { id: number; name: string; slug: string; active: boolean; thumbnail?: string | null };
export type Post = {
  id: number; title: string; slug: string; summary: string | null;
  thumbnail: string; content: string | null; categoryId: number; categoryName: string;
  publishedAt: string; viewCount: number;
};
export class PostRequestError extends Error {
  constructor(message: string, public status = 0) { super(message); this.name = "PostRequestError"; }
}
export const isPostAbort = (error: unknown) => error instanceof Error && error.name === "AbortError";

async function request<T>(path: string, signal?: AbortSignal, options: { method?: string; body?: object } = {}): Promise<T> {
  const controller = new AbortController();
  const abort = () => controller.abort();
  if (signal?.aborted) controller.abort();
  signal?.addEventListener("abort", abort, { once: true });
  const timer = setTimeout(() => controller.abort(), 15000);
  try {
    const response = await apiRequest(path, { ...options, signal: controller.signal, cache: "no-store" });
    if (response?.data == null) throw new PostRequestError("Dữ liệu bài viết trả về không hợp lệ. Vui lòng thử lại.");
    return response.data as T;
  } catch (error) {
    if (signal?.aborted) throw new DOMException("Request cancelled", "AbortError");
    if (controller.signal.aborted) { reportConnectionFailure(); throw new PostRequestError("Máy chủ phản hồi quá lâu. Vui lòng thử lại."); }
    if (error instanceof ApiClientError) throw new PostRequestError(error.status === 404 ? "Bài viết không tồn tại hoặc đã được ẩn." : error.message, error.status);
    if (error instanceof PostRequestError) throw error;
    throw new PostRequestError("Không kết nối được máy chủ bài viết. Vui lòng thử lại.");
  } finally {
    clearTimeout(timer); signal?.removeEventListener("abort", abort);
  }
}
export async function listPosts(q = "", categoryId = "", page = 0, size = 12, signal?: AbortSignal): Promise<PageResponse<Post>> {
  const params = new URLSearchParams({ q: q.trim(), page: String(Math.max(0, page)), size: String(Math.max(1, Math.min(100, size))) });
  if (categoryId) params.set("categoryId", categoryId);
  const data = await request<PageResponse<Post>>(`/posts?${params}`, signal);
  if (!Array.isArray(data.content) || !Number.isInteger(data.totalPages) || !Number.isInteger(data.totalElements) || !Number.isInteger(data.number)) throw new PostRequestError("Danh sách bài viết trả về không hợp lệ.");
  return data;
}
export async function postCategories(signal?: AbortSignal): Promise<PostCategory[]> {
  const data = await request<PostCategory[]>("/posts/categories", signal);
  if (!Array.isArray(data)) throw new PostRequestError("Danh mục bài viết trả về không hợp lệ.");
  return data.filter(c => c.active);
}
export async function readPost(slug: string, signal?: AbortSignal): Promise<Post> {
  const data = await request<Post>(`/posts/${encodeURIComponent(slug)}`, signal);
  if (!data.slug || typeof data.content !== "string") throw new PostRequestError("Nội dung bài viết trả về không hợp lệ.");
  return data;
}
export type PostViewSession = { token: string; minimumSeconds: number };
export type PopularPost = Omit<Post, "content">;
export async function popularPosts(signal?: AbortSignal, size = 1): Promise<PopularPost[]> {
  const data = await request<PopularPost[]>(size === 1 ? "/posts/popular" : `/posts/popular?size=${Math.max(1, Math.min(5, Math.trunc(size)))}`, signal);
  if (!Array.isArray(data) || data.some(p => !Number.isSafeInteger(p.viewCount) || p.viewCount < 1))
    throw new PostRequestError("Danh sách bài viết được đọc nhiều trả về không hợp lệ.");
  return data;
}
export type PostViewResult = { counted: boolean; viewCount: number };
export const startPostView = (slug: string, signal?: AbortSignal) => request<PostViewSession>(`/posts/${encodeURIComponent(slug)}/view-session`, signal, { method: "POST" });
export const recordPostView = (slug: string, token: string, signal?: AbortSignal) => request<PostViewResult>(`/posts/${encodeURIComponent(slug)}/views`, signal, { method: "POST", body: { token } });
export async function recommendedPosts(signal?: AbortSignal, categoryId?: number): Promise<Post[]> {
  const data = await request<Post[]>(`/posts/recommendations${categoryId == null ? "" : `?categoryId=${categoryId}`}`, signal);
  if (!Array.isArray(data)) throw new PostRequestError("Danh sách đề xuất trả về không hợp lệ.");
  return data;
}
export type JournalSection = PostCategory & { image: string | null; posts: Post[]; error: string | null };
export async function loadPostJournal(signal?: AbortSignal) {
  const [posts, categories, recommendations] = await Promise.allSettled([listPosts("", "", 0, 1, signal), postCategories(signal), recommendedPosts(signal)]);
  if (signal?.aborted) throw new DOMException("Request cancelled", "AbortError");
  const sections: JournalSection[] = categories.status === "fulfilled" ? await Promise.all(categories.value.map(async c => {
    try {
      const page = await listPosts("", String(c.id), 0, 3, signal);
      return { ...c, posts: page.content, image: c.thumbnail ?? null, error: null };
    } catch (error) {
      if (signal?.aborted) throw error;
      return { ...c, posts: [], image: c.thumbnail ?? null, error: error instanceof Error ? error.message : "Không tải được bài viết của danh mục." };
    }
  })) : [];
  return { posts: posts.status === "fulfilled" ? posts.value.content : [], sections,
    recommendations: recommendations.status === "fulfilled" ? recommendations.value : [],
    recommendationsError: recommendations.status === "rejected" ? (recommendations.reason as Error).message : null,
    postsError: posts.status === "rejected" ? (posts.reason as Error).message : null,
    categoriesError: categories.status === "rejected" ? (categories.reason as Error).message : null };
}
export const postDate = (date: string) => {
  const value = new Date(date);
  return Number.isNaN(value.getTime()) ? "" : value.toLocaleDateString("vi-VN", { timeZone: "Asia/Ho_Chi_Minh" });
};
