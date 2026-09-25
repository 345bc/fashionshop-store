const trimTrailingSlash = (value) => value.replace(/\/$/, "");

const BACKEND_URL = trimTrailingSlash(
  process.env.NEXT_PUBLIC_BACKEND_URL || "http://localhost:8080",
);
const API_BASE_URL = trimTrailingSlash(
  process.env.NEXT_PUBLIC_API_BASE_URL || `${BACKEND_URL}/api/v1`,
);

let csrf = null;

export class ApiClientError extends Error {
  constructor(message, status, code, details = []) {
    super(message);
    this.name = "ApiClientError";
    this.status = status;
    this.code = code;
    this.details = details;
    this.isUnauthorized = status === 401;
    this.isForbidden = status === 403;
  }
}

function isJsonBody(body) {
  return (
    body != null &&
    typeof body !== "string" &&
    !(body instanceof FormData) &&
    !(body instanceof Blob)
  );
}

function isUnsafeMethod(method) {
  return !["GET", "HEAD", "OPTIONS"].includes(method);
}

async function getCsrf() {
  if (csrf) return csrf;

  const response = await fetch(`${API_BASE_URL}/auth/csrf`, {
    credentials: "include",
    headers: { Accept: "application/json" },
  });
  const payload = await response.json().catch(() => null);

  if (!response.ok || !payload?.data?.headerName || !payload?.data?.token) {
    throw new ApiClientError(
      payload?.message ?? "Không thể khởi tạo phiên bảo mật",
      response.status,
      payload?.code ?? "CSRF_INIT_FAILED",
      payload?.errors ?? [],
    );
  }

  csrf = payload.data;
  return csrf;
}

export function clearCsrfToken() {
  csrf = null;
}

export async function apiRequest(path, options = {}) {
  const method = (options.method ?? "GET").toUpperCase();
  const headers = new Headers(options.headers);
  headers.set("Accept", "application/json");

  if (isJsonBody(options.body)) {
    headers.set("Content-Type", "application/json");
  }
  if (isUnsafeMethod(method) && options.csrf !== false) {
    const token = await getCsrf();
    headers.set(token.headerName, token.token);
  }

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    method,
    credentials: "include",
    headers,
    body: isJsonBody(options.body)
      ? JSON.stringify(options.body)
      : options.body,
  });

  const isJson = response.headers
    .get("content-type")
    ?.includes("application/json");
  const payload = isJson ? await response.json() : null;

  if (!response.ok) {
    if (response.status === 401 || response.status === 403) {
      clearCsrfToken();
    }
    throw new ApiClientError(
      payload?.message ??
        (response.status === 401
          ? "Phiên đăng nhập đã hết hạn"
          : response.status === 403
            ? "Bạn không có quyền thực hiện thao tác này"
            : "Không thể kết nối đến máy chủ"),
      response.status,
      payload?.code ??
        (response.status === 401
          ? "AUTHENTICATION_REQUIRED"
          : response.status === 403
            ? "ACCESS_DENIED"
            : "REQUEST_FAILED"),
      payload?.errors ?? [],
    );
  }

  return payload;
}

export async function apiDownload(path) {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    credentials: "include",
  });
  if (!response.ok) {
    if (response.status === 401 || response.status === 403) {
      clearCsrfToken();
    }
    throw new ApiClientError(
      response.status === 401
        ? "Phiên đăng nhập đã hết hạn"
        : response.status === 403
          ? "Bạn không có quyền tải tệp này"
          : "Không thể tải tệp",
      response.status,
      response.status === 401
        ? "AUTHENTICATION_REQUIRED"
        : response.status === 403
          ? "ACCESS_DENIED"
          : "DOWNLOAD_FAILED",
    );
  }
  return response.blob();
}

export function saveBlob(blob, filename) {
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
}

export { API_BASE_URL, BACKEND_URL };
