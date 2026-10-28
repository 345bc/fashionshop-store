import { apiRequest } from "@/api/apiClient";

export type Detection = {
  label: string;
  confidence: number;
  box: number[];
  colors: { label: string; confidence: number }[];
};
export type Recognition = {
  width: number;
  height: number;
  detections: Detection[];
  suggestions?: CatalogSuggestion[];
};

export type CatalogSuggestion = {
  label: string;
  color: string;
  colorMatched: boolean;
  products: {
    id: number;
    name: string;
    slug: string;
    imageUrl?: string;
    basePrice: number;
    salePrice?: number;
  }[];
};

export async function recognizeImage(
  image: string,
  signal: AbortSignal,
): Promise<Recognition> {
  const response = await apiRequest("/chat/image-recognition", {
    method: "POST",
    body: { image },
    signal,
    timeoutMs: 120000,
    localErrorHandling: true,
  });
  const result = response.data as Recognition;
  if (
    !result ||
    !Array.isArray(result.detections) ||
    result.detections.some(
      (item) =>
        typeof item.label !== "string" ||
        !Number.isFinite(item.confidence) ||
        !Array.isArray(item.colors) ||
        item.colors.some(
          (color) =>
            typeof color.label !== "string" ||
            !Number.isFinite(color.confidence),
        ),
    )
  ) {
    throw new Error("Kết quả nhận diện không hợp lệ. Vui lòng thử lại.");
  }
  if (
    result.suggestions !== undefined &&
    (!Array.isArray(result.suggestions) ||
      result.suggestions.some(
        (group) =>
          typeof group.label !== "string" ||
          typeof group.color !== "string" ||
          typeof group.colorMatched !== "boolean" ||
          !Array.isArray(group.products) ||
          group.products.some(
            (product) =>
              !Number.isFinite(product.id) ||
              typeof product.name !== "string" ||
              typeof product.slug !== "string" ||
              !product.slug ||
              !Number.isFinite(Number(product.basePrice)),
          ),
      ))
  ) {
    throw new Error("Danh sách sản phẩm gợi ý không hợp lệ. Vui lòng thử lại.");
  }
  return result;
}

const garmentNames: Record<string, string> = {
  Blazer: "áo blazer",
  Blouse: "áo kiểu",
  "Button-Down": "áo sơ mi",
  Cardigan: "áo cardigan",
  Hoodie: "áo hoodie",
  Jacket: "áo khoác",
  Sweater: "áo len",
  Tank: "áo ba lỗ",
  Tee: "áo thun",
  Jeans: "quần jeans",
  Joggers: "quần jogger",
  Leggings: "quần legging",
  Shorts: "quần short",
  Skirt: "chân váy",
  Sweatpants: "quần nỉ",
  Coat: "áo khoác dài",
  Dress: "đầm",
};
const colorNames: Record<string, string> = {
  black: "đen",
  white: "trắng",
  grey: "xám",
  gray: "xám",
  blue: "xanh dương",
  green: "xanh lá",
  red: "đỏ",
  pink: "hồng",
  purple: "tím",
  yellow: "vàng",
  orange: "cam",
  brown: "nâu",
  beige: "be",
  multi: "đa màu",
};
export function garmentName(label: string): string {
  return garmentNames[label] ?? label;
}
export function catalogSearchUrl(label: string): string {
  return `/products?q=${encodeURIComponent(garmentName(label))}`;
}
export function describeRecognition(result: Recognition): string {
  if (!result.detections.length)
    return "Mình chưa phát hiện được quần áo trong ảnh. Bạn thử gửi ảnh rõ hơn, thấy đầy đủ sản phẩm nhé.";
  const description = result.detections
    .map((item) => {
      const color = [...item.colors].sort(
        (a, b) => b.confidence - a.confidence,
      )[0];
      const name = garmentName(item.label);
      return `${name}${name !== item.label ? ` (${item.label})` : ""}${color ? ` màu ${colorNames[color.label.toLowerCase()] ?? color.label}` : ""}`;
    })
    .join(", ");
  const introduction = `Mình nhận thấy trang phục trong ảnh có vẻ là ${description}.`;
  if (!result.suggestions) return introduction;
  const hasProducts = result.suggestions.some(
    (group) => group.products.length > 0,
  );
  if (!hasProducts)
    return `${introduction}\n\nRất tiếc, hiện chưa tìm thấy sản phẩm phù hợp đang còn hàng.\n\nBạn có thể khám phá những mẫu ${garmentName(result.detections[0].label)} khác tại Zella hoặc thử tìm kiếm bằng một hình ảnh khác nhé!`;
  return `${introduction}\n\nMình tìm được một số sản phẩm để bạn tham khảo bên dưới.`;
}
