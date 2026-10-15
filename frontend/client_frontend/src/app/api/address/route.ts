const API = "https://provinces.open-api.vn/api/v2";

export async function GET(request: Request) {
  const provinceCode = new URL(request.url).searchParams.get("provinceCode");
  if (provinceCode !== null && (!/^[1-9]\d{0,2}$/.test(provinceCode))) {
    return Response.json({ message: "Mã tỉnh/thành phố không hợp lệ" }, { status: 400 });
  }
  try {
    const response = await fetch(provinceCode ? `${API}/w/?province=${provinceCode}` : `${API}/p/`, {
      next: { revalidate: 86400 }, signal: AbortSignal.timeout(10000),
    });
    if (!response.ok) throw new Error("Address API unavailable");
    const data: unknown = await response.json();
    if (!Array.isArray(data) || data.length === 0 || data.some(item =>
      !item || !Number.isInteger(item.code) || typeof item.name !== "string" || !item.name.trim()
      || (provinceCode !== null && item.province_code !== Number(provinceCode)))) {
      throw new Error("Invalid address data");
    }
    return Response.json(data.map(item => ({ code: item.code as number, name: item.name as string })), {
      headers: { "Cache-Control": "public, max-age=3600" },
    });
  } catch {
    return Response.json({ message: "Chưa tải được danh sách địa chỉ. Vui lòng thử lại" }, {
      status: 503, headers: { "Cache-Control": "no-store" },
    });
  }
}
