import { apiRequest } from "../../../api/apiClient";

// export function listOutgoingDocuments({ q = "", page = 0, size = 20 } = {}) {
//   const query = new URLSearchParams({ q, page, size });
//   return apiRequest(`/outgoing-documents?${query}`);
// }

export function getIdByUserId(userId) {
  return apiRequest(`/customers/user/${userId}`);
}

// export function createOutgoingDocument(payload) {
//   return apiRequest("/outgoing-documents", { method: "POST", body: payload });
// }

// export function updateOutgoingDocument(id, payload) {
//   return apiRequest(`/outgoing-documents/${id}`, { method: "PUT", body: payload });
// }
