import { apiRequest } from "../api/apiClient";

/**
 * @typedef {{ id: number, name: string, hexCode: string }} ColorOption
 */

/**
 * @param {AbortSignal} [signal]
 * @returns {Promise<ColorOption[]>}
 */
export async function getColorOptions(signal) {
  const colors = [];
  let page = 0;
  let totalPages;

  do {
    const response = await apiRequest(`/color?page=${page}&size=100`, {
      signal,
    });

    colors.push(...response.data.content);
    totalPages = response.data.totalPages;
    page += 1;
  } while (page < totalPages);

  return colors;
}
