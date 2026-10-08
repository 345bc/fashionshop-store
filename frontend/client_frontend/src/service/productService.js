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
 */
export function getProductCards({
  q = "",
  categoryId = null,
  page = 0,
  size = 12,
  sort = "featured",
  signal = undefined,
  colorIds = [],
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

  if (categoryId != null) {
    params.set("categoryId", String(categoryId));
  }

  return apiRequest(`/product/cards?${params}`, { signal });
}
