import { apiRequest } from "../api/apiClient";

export function getCategoriesParent() {
  return apiRequest(`/category/parents`);
}

export function getCategories(parentId) {
  return apiRequest(`/category/parents/${parentId}`);
}
