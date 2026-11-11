import { apiRequest, BACKEND_URL } from "@/api/apiClient";

export type ChatButton = { title: string; payload: string };
export type ChatProductReference = { name: string; slug: string };
export type ChatProduct = ChatProductReference & { id: string; price: number; imageUrl?: string };
export type SizeGuide = { product: string; slug?: string; sizes: string[]; chartUrl?: string };
export type ChatReply = {
  text: string;
  botImage?: string;
  buttons?: ChatButton[];
  products?: ChatProduct[];
  productReference?: ChatProductReference;
  sizeGuide?: SizeGuide;
};
export type ChatResult = { conversationId: string; messages: ChatReply[]; fallback: boolean };

function object(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

export function safeChatMedia(value: unknown): string | undefined {
  if (typeof value !== "string" || !value || value.length > 4096) return undefined;
  try {
    const url = new URL(value, `${BACKEND_URL}/`);
    return ["http:", "https:"].includes(url.protocol) && !url.username && !url.password ? url.href : undefined;
  } catch { return undefined; }
}

function validSlug(value: unknown): value is string {
  return typeof value === "string" && /^[a-zA-Z0-9][a-zA-Z0-9-]{0,199}$/.test(value);
}

function products(value: unknown): ChatProduct[] {
  if (!Array.isArray(value)) return [];
  return value.slice(0, 20).flatMap(item => {
    if (!object(item) || !["string", "number"].includes(typeof item.id) ||
        typeof item.name !== "string" || !item.name.trim() || !validSlug(item.slug)) return [];
    const price = item.price ?? item.salePrice ?? item.basePrice;
    if (typeof price !== "number" || !Number.isFinite(price) || price < 0) return [];
    return [{ id: String(item.id), name: item.name, slug: item.slug, price, imageUrl: safeChatMedia(item.imageUrl) }];
  });
}

function normalizeReply(value: unknown): ChatReply | undefined {
  if (!object(value)) return undefined;
  const text = typeof value.text === "string"
    ? value.text.replace(/Mình chưa đọc được số đo từ ảnh để chốt size chỉ theo chiều cao\s*\/\s*cân nặng\.?/giu, "").trim()
    : "";
  const reply: ChatReply = { text: text.trimStart().startsWith("Cơ sở tìm:") ? "" : text };
  reply.botImage = safeChatMedia(value.image);
  if (Array.isArray(value.buttons)) {
    reply.buttons = value.buttons.slice(0, 20).flatMap(button =>
      object(button) && typeof button.title === "string" && button.title.trim() &&
      typeof button.payload === "string" && button.payload.trim() && button.payload.length <= 1000
        ? [{ title: button.title, payload: button.payload }] : []);
  }
  if (object(value.custom)) {
    const isRasaProductList = value.custom.type === "PRODUCT_LIST";
    if (isRasaProductList || value.custom.type === "products") {
      reply.products = products(value.custom.products);
      if (isRasaProductList && reply.products.length) reply.text = "";
    }
    if (value.custom.type === "PRODUCT_DETAIL" && object(value.custom.product)) {
      const { name, slug } = value.custom.product;
      if (typeof name === "string" && name.trim() && validSlug(slug)) reply.productReference = { name, slug };
    }
    if (value.custom.type === "size_guide" && typeof value.custom.product === "string") {
      reply.sizeGuide = {
        product: value.custom.product,
        slug: validSlug(value.custom.slug) ? value.custom.slug : undefined,
        sizes: Array.isArray(value.custom.sizes) ? value.custom.sizes.filter((size): size is string => typeof size === "string").slice(0, 30) : [],
        chartUrl: safeChatMedia(value.custom.chartUrl),
      };
    }
  }
  return reply.text.trim() || reply.botImage || reply.buttons?.length || reply.products?.length || reply.sizeGuide ? reply : undefined;
}

function normalizeReplies(values: unknown[]): ChatReply[] {
  const replies = values.map(normalizeReply).filter((reply): reply is ChatReply => reply !== undefined);
  const images = new Set(replies.map(reply => reply.botImage).filter(Boolean));
  const guides = new Map(replies.flatMap(({ sizeGuide }) =>
    sizeGuide?.chartUrl && sizeGuide.slug
      ? [[sizeGuide.chartUrl, { name: sizeGuide.product, slug: sizeGuide.slug }] as const]
      : []
  ));
  const productNames = new Set(replies.flatMap(reply => (reply.products ?? []).map(product => product.name.trim())));
  return replies.flatMap(reply => {
    const summary = reply.text.split(/\r?\n/).filter(line => {
      const productRow = line.match(/^\s*\d+\.\s+(.+?)\s+[—–-]\s+[\d.,]+\s*[đ₫]/iu);
      return !productRow || !productNames.has(productRow[1].trim());
    }).join("\n").trim();
    const text = summary === "Mình tìm được:" && productNames.size
      ? `Mình tìm được ${productNames.size} mẫu phù hợp với yêu cầu của bạn. Bạn có thể mở thẻ để xem chi tiết hoặc gửi tên mẫu để mình kiểm tra còn hàng hay tư vấn size nhé.`
      : summary;
    const sizeGuide = reply.sizeGuide?.chartUrl && images.has(reply.sizeGuide.chartUrl) ? undefined : reply.sizeGuide;
    return text || reply.botImage || reply.buttons?.length || reply.products?.length || sizeGuide
      ? [{ ...reply, text, sizeGuide, productReference: reply.productReference ?? guides.get(reply.botImage ?? "") }]
      : [];
  });
}

export async function sendChatMessage(message: string, conversationId: string | undefined, signal: AbortSignal): Promise<ChatResult> {
  const text = message.trim();
  if (!text || text.length > 1000) throw new Error("Vui lòng nhập tin nhắn tối đa 1000 ký tự.");
  const response = await apiRequest("/chat/messages", {
    method: "POST",
    body: { message: text, ...(conversationId ? { conversationId } : {}) },
    signal,
    timeoutMs: 135000,
    localErrorHandling: true,
  });
  const data: unknown = response?.data;
  if (!object(data) || typeof data.conversationId !== "string" ||
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(data.conversationId) ||
      !Array.isArray(data.messages)) throw new Error("Phản hồi của trợ lý không hợp lệ. Bạn thử lại nhé.");
  const messages = normalizeReplies(data.messages);
  if (!messages.length) throw new Error("Trợ lý chưa có phản hồi. Bạn thử hỏi lại nhé.");
  return { conversationId: data.conversationId, messages, fallback: data.fallback === true };
}
