import { apiRequest } from "../api/apiClient";

export function getSize() {
  return apiRequest(`/size`);
}
