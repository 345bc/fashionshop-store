import { beforeEach, describe, expect, it, vi } from "vitest";
import { apiRequest, clearCsrfToken } from "./apiClient";

function jsonResponse(data) {
  return {
    ok: true,
    status: 200,
    headers: new Headers({ "content-type": "application/json" }),
    json: vi.fn().mockResolvedValue(data),
  };
}

describe("apiRequest", () => {
  beforeEach(() => {
    clearCsrfToken();
    vi.restoreAllMocks();
  });

  it("gửi session cookie và CSRF header cho request ghi dữ liệu", async () => {
    const fetchMock = vi
      .spyOn(globalThis, "fetch")
      .mockResolvedValueOnce(jsonResponse({
        data: { headerName: "X-XSRF-TOKEN", token: "csrf-demo" },
      }))
      .mockResolvedValueOnce(jsonResponse({ data: { id: 1 } }));

    await apiRequest("/reference-items", {
      method: "POST",
      body: { name: "Bản ghi mẫu" },
    });

    const request = fetchMock.mock.calls[1][1];
    expect(request.credentials).toBe("include");
    expect(request.headers.get("X-XSRF-TOKEN")).toBe("csrf-demo");
    expect(request.headers.has("Authorization")).toBe(false);
  });
});
