/* eslint-disable @typescript-eslint/no-require-imports */
const { test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const Module = require("node:module");
const ts = require("typescript");

const id = "c6175c59-fca7-44cd-b37b-a72a9316e514";
function service(request) {
  const filename = path.resolve(__dirname, "../src/service/chatService.ts");
  const loaded = new Module(filename, module);
  loaded.paths = Module._nodeModulePaths(path.dirname(filename));
  loaded.require = name => name === "@/api/apiClient" ? { apiRequest: request, BACKEND_URL: "http://localhost:8080" } : require(name);
  loaded._compile(ts.transpileModule(fs.readFileSync(filename, "utf8"), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
  }).outputText, filename);
  return loaded.exports;
}

test("chat uses the authenticated backend, preserves the conversation and handles outages locally", async () => {
  const signal = new AbortController().signal;
  const api = service(async (route, options) => {
    assert.equal(route, "/chat/messages");
    assert.deepEqual(options.body, { message: "Tư vấn kiểu dáng", conversationId: id });
    assert.equal(options.signal, signal);
    assert.equal(options.localErrorHandling, true);
    assert.ok(options.timeoutMs > 120000);
    assert.equal(options.body.sender, undefined);
    assert.equal(options.body.userId, undefined);
    return { data: { conversationId: id, messages: [{ text: "Bạn thích phong cách nào?" }], fallback: false } };
  });
  const out = await api.sendChatMessage(" Tư vấn kiểu dáng ", id, signal);
  assert.equal(out.conversationId, id);
  assert.equal(out.messages[0].text, "Bạn thích phong cách nào?");
});

test("first message lets the backend generate a conversation id", async () => {
  await service(async (_, options) => {
    assert.deepEqual(options.body, { message: "Xin chào" });
    return { data: { conversationId: id, messages: [{ text: "Chào bạn" }] } };
  }).sendChatMessage("Xin chào", undefined, new AbortController().signal);
});

test("normalizes real product cards, product-specific charts and action buttons", async () => {
  const api = service(async () => ({ data: { conversationId: id, messages: [
    { text: "Sản phẩm phù hợp", recipient_id: "private-rasa-sender" },
    { custom: { type: "products", products: [{ id: 1, name: "Áo", slug: "ao-so-mi", basePrice: 200000, salePrice: 190000, imageUrl: "/images/ao.png", productUrl: "https://untrusted.example" }] } },
    { image: "https://images.example/chart.png" },
    { custom: { type: "size_guide", product: "Áo", slug: "ao-so-mi", sizes: ["M", "L"], chartUrl: "https://images.example/chart.png" } },
    { buttons: [{ title: "Tư vấn size", payload: "Tư vấn size sản phẩm ao-so-mi" }] },
  ] } }));
  const out = await api.sendChatMessage("Tìm áo", id, new AbortController().signal);
  assert.equal(out.messages[1].products[0].price, 190000);
  assert.equal(out.messages[1].products[0].imageUrl, "http://localhost:8080/images/ao.png");
  assert.equal(out.messages[1].products[0].productUrl, undefined);
  assert.equal(out.messages[2].botImage, "https://images.example/chart.png");
  assert.deepEqual(out.messages[3].sizeGuide.sizes, ["M", "L"]);
  assert.equal(out.messages[4].buttons[0].payload, "Tư vấn size sản phẩm ao-so-mi");
  assert.doesNotMatch(JSON.stringify(out), /private-rasa-sender/);
});

test("rejects executable media, invalid prices and product paths outside the catalog", async () => {
  const api = service(async () => ({ data: { conversationId: id, messages: [{ text: "Kết quả", image: "javascript:alert(1)", custom: {
    type: "products", products: [
      { id: 1, name: "Bad", slug: "../admin", price: 1 },
      { id: 2, name: "Bad price", slug: "ao", price: -10 },
      { id: 3, name: "Áo", slug: "ao", price: 100, imageUrl: "data:text/html,bad" },
    ],
  } }] } }));
  const reply = (await api.sendChatMessage("Tìm áo", id, new AbortController().signal)).messages[0];
  assert.equal(reply.botImage, undefined);
  assert.equal(reply.products.length, 1);
  assert.equal(reply.products[0].imageUrl, undefined);
  assert.equal(api.safeChatMedia("https://user:secret@images.example/a.png"), undefined);
});

test("malformed responses and upstream errors remain visible errors, not fabricated advice", async () => {
  const signal = new AbortController().signal;
  for (const data of [{}, { conversationId: "bad", messages: [{ text: "Hi" }] }, { conversationId: id, messages: [] }]) {
    await assert.rejects(service(async () => ({ data })).sendChatMessage("hi", id, signal), /không hợp lệ|chưa có phản hồi/);
  }
  await assert.rejects(service(async () => { throw new Error("Trợ lý chưa sẵn sàng"); }).sendChatMessage("hi", id, signal), /chưa sẵn sàng/);
  await assert.rejects(service().sendChatMessage(" ", id, signal), /tối đa 1000/);
  await assert.rejects(service().sendChatMessage("x".repeat(1001), id, signal), /tối đa 1000/);
});
