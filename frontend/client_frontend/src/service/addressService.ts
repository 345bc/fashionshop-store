export type AddressOption = { code: number; name: string };

async function getAddressOptions(provinceCode?: number, signal?: AbortSignal): Promise<AddressOption[]> {
  const response = await fetch(`/api/address${provinceCode ? `?provinceCode=${provinceCode}` : ""}`, { signal });
  if (!response.ok) throw new Error("Chưa tải được danh sách địa chỉ. Vui lòng thử lại");
  return response.json();
}

export function getProvinces(signal?: AbortSignal) {
  return getAddressOptions(undefined, signal);
}

export function getWards(provinceCode: number, signal?: AbortSignal) {
  return getAddressOptions(provinceCode, signal);
}
