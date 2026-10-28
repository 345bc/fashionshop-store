/* eslint-disable @typescript-eslint/no-require-imports */
const { test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const Module = require("node:module");
const ts = require("typescript");
function service(request) {
  const filename = path.resolve(
    __dirname,
    "../src/service/imageRecognitionService.ts",
  );
  const loaded = new Module(filename, module);
  loaded.paths = Module._nodeModulePaths(path.dirname(filename));
  loaded.require = (name) =>
    name === "@/api/apiClient" ? { apiRequest: request } : require(name);
  loaded._compile(
    ts.transpileModule(fs.readFileSync(filename, "utf8"), {
      compilerOptions: {
        module: ts.ModuleKind.CommonJS,
        target: ts.ScriptTarget.ES2022,
      },
    }).outputText,
    filename,
  );
  return loaded.exports;
}
const result = {
  width: 100,
  height: 100,
  detections: [
    {
      label: "Áo thun",
      confidence: 0.95,
      box: [0, 0, 100, 100],
      colors: [{ label: "Đen", confidence: 0.9 }],
    },
  ],
};
test("catalog suggestions retain product links and explicit color fallback", async () => {
  const payload = { ...result, suggestions: [{ label: "Blazer", color: "beige", colorMatched: false,
    products: [{ id: 1, slug: "ao-blazer", name: "Áo blazer", basePrice: 200000 }] }] };
  const api = service(async () => ({ data: payload }));
  assert.deepEqual(await api.recognizeImage("image", new AbortController().signal), payload);
  assert.match(api.describeRecognition(payload), /sản phẩm để bạn tham khảo/);
  await assert.rejects(service(async () => ({ data: { ...result, suggestions: [{}] } })).recognizeImage("image", new AbortController().signal), /không hợp lệ/);
});
test("image request uses authenticated store endpoint and handles model failures within chat", async () => {
  const signal = new AbortController().signal;
  const api = service(async (route, options) => {
    assert.equal(route, "/chat/image-recognition");
    assert.equal(options.method, "POST");
    assert.deepEqual(options.body, { image: "data:image/png;base64,test" });
    assert.equal(options.signal, signal);
    assert.equal(options.timeoutMs, 120000);
    assert.equal(options.localErrorHandling, true);
    return { data: result };
  });
  assert.deepEqual(
    await api.recognizeImage("data:image/png;base64,test", signal),
    result,
  );
});
test("both model outputs are described without inventing catalog matches", () => {
  const api = service();
  const text = api.describeRecognition(result);
  assert.match(text, /Áo thun/);
  assert.match(text, /màu Đen/);
  assert.doesNotMatch(text, /độ tin cậy|%/);
  assert.match(
    api.describeRecognition({ width: 10, height: 10, detections: [] }),
    /chưa phát hiện/,
  );
});
test("malformed model responses and API failures remain errors", async () => {
  const signal = new AbortController().signal;
  await assert.rejects(
    service(async () => ({ data: {} })).recognizeImage("image", signal),
    /không hợp lệ/,
  );
  await assert.rejects(
    service(async () => {
      throw new Error("AI unavailable");
    }).recognizeImage("image", signal),
    /AI unavailable/,
  );
});

test("empty catalog uses conversational copy and a working product search link", () => {
  const api = service();
  const text = api.describeRecognition({ ...result, detections: [{ ...result.detections[0], label: "Sweater", colors: [{label: "brown", confidence: .9}] }], suggestions: [] });
  assert.match(text, /áo len \(Sweater\) màu nâu/);
  assert.match(text, /chưa tìm thấy sản phẩm phù hợp đang còn hàng/);
  assert.equal(api.catalogSearchUrl("Sweater"), `/products?q=${encodeURIComponent("áo len")}`);
});
