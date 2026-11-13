import { apiRequest } from "../api/apiClient";

/**
 * @param {Object} params
 * @param {string} [params.q=""]
 * @param {number|null} [params.categoryId=null]
 * @param {number[]} [params.categoryIds]
 * @param {number} [params.page=0]
 * @param {number} [params.size=12]
 * @param {AbortSignal} [params.signal]
 * @param {string} [params.sort="featured"]
 * @param {number[]} [params.colorIds]
 * @param {number[]} [params.sizeIds]
 * @param {number|null} [params.minPrice]
 * @param {number|null} [params.maxPrice]
 * @param {number|null} [params.campaignId]
 * @param {boolean} [params.newProducts]
 */
export function getProductCards({
  q = "",
  categoryId = null,
  categoryIds = [],
  page = 0,
  size = 12,
  sort = "featured",
  signal = undefined,
  colorIds = [],
  sizeIds = [],
  minPrice = null,
  maxPrice = null,
  campaignId = null,
  newProducts = false,
} = {}) {
  const params = new URLSearchParams({
    q,
    page: String(page),
    size: String(size),
    sort,
  });
  categoryIds.forEach(id => params.append("categoryIds", String(id)));
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

  if (campaignId != null) params.set("campaignId", String(campaignId));
  if (newProducts) params.set("new", "true");

  return apiRequest(`/product/cards?${params}`, { signal });
}

export function getProductDetail(slug, { signal } = {}) {
  return apiRequest(`/product/detail/${slug}`, { signal });
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

/**
 * @param {{productId: number, size?: number, signal?: AbortSignal}} options
 * @returns {Promise<import("../type/api").ApiResponse<{computedAt: string, totalTransactions: number, products: {product: import("../type/product").ProductCardData, transactions: number, support: number, confidence: number, lift: number}[]}>>}
 */
export function getBoughtTogether({ productId, size = 8, signal }) {
  return apiRequest(`/product/${productId}/bought-together?size=${size}`, { signal });
}
