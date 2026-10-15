import { apiRequest } from "../api/apiClient";

/**
 * @param {Object} params
 * @param {string} [params.q=""]
 * @param {number|null} [params.categoryId=null]
 * @param {number} [params.page=0]
 * @param {number} [params.size=12]
 * @param {AbortSignal} [params.signal]
 * @param {string} [params.sort="featured"]
 * @param {number[]} [params.colorIds]
 * @param {number[]} [params.sizeIds]
 * @param {number|null} [params.minPrice]
 * @param {number|null} [params.maxPrice]
 */
export function getProductCards({
  q = "",
  categoryId = null,
  page = 0,
  size = 12,
  sort = "featured",
  signal = undefined,
  colorIds = [],
  sizeIds = [],
  minPrice = null,
  maxPrice = null,
} = {}) {
  const params = new URLSearchParams({
    q,
    page: String(page),
    size: String(size),
    sort,
  });
  colorIds.forEach((id) => {
    params.append("colorIds", String(id));
  });
  sizeIds.forEach((id) => {
    params.append("sizeIds", String(id));
  });

  if (categoryId != null) {
    params.set("categoryId", String(categoryId));
  }

  if (minPrice != null) {
    params.set("minPrice", String(minPrice));
  }
  if (maxPrice != null) {
    params.set("maxPrice", String(maxPrice));
  }

  return apiRequest(`/product/cards?${params}`, { signal });
}

export function getProductDetail(slug, { signal } = {}) {
  return apiRequest(`/product/detail/${slug}`, { signal });
}

/**
 * @param {{page?: number, size?: number, signal?: AbortSignal}} [options]
 * @returns {Promise<import("../type/api").ApiResponse<import("../type/api").PageResponse<import("../type/product").ProductCardData>>>}
 */
export function getNewArrivals({ page = 0, size = 12, signal } = {}) {
  const params = new URLSearchParams({
    page: String(page),
    size: String(size),
  });
  return apiRequest(`/product/new-arrivals?${params}`, { signal });
}

/**
 * @param {{productId: number, page?: number, size?: number, signal?: AbortSignal}} options
 * @returns {Promise<import("../type/api").ApiResponse<import("../type/api").PageResponse<import("../type/product").ProductCardData>>>}
 */
export function getSimilars({ productId, page = 0, size = 8, signal }) {
  const params = new URLSearchParams({
    page: String(page),
    size: String(size),
    productId: String(productId),
  });
  return apiRequest(`/product/similars?${params}`, { signal });
}
