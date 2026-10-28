import { apiRequest, BACKEND_URL } from "@/api/apiClient";

export type ChatButton = { title: string; payload: string };
export type ChatProduct = { id: string; name: string; slug: string; price: number; imageUrl?: string };
export type SizeGuide = { product: string; slug?: string; sizes: string[]; chartUrl?: string };
export type ChatReply = {
  text: string;
  botImage?: string;
  buttons?: ChatButton[];
  products?: ChatProduct[];
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
  const reply: ChatReply = { text: typeof value.text === "string" ? value.text : "" };
  reply.botImage = safeChatMedia(value.image);
  if (Array.isArray(value.buttons)) {
    reply.buttons = value.buttons.slice(0, 20).flatMap(button =>
      object(button) && typeof button.title === "string" && button.title.trim() &&
      typeof button.payload === "string" && button.payload.trim() && button.payload.length <= 1000
        ? [{ title: button.title, payload: button.payload }] : []);
  }
  if (object(value.custom)) {
    if (value.custom.type === "products") reply.products = products(value.custom.products);
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
  const messages = data.messages.map(normalizeReply).filter((reply): reply is ChatReply => reply !== undefined);
  if (!messages.length) throw new Error("Trợ lý chưa có phản hồi. Bạn thử hỏi lại nhé.");
  return { conversationId: data.conversationId, messages, fallback: data.fallback === true };
}
