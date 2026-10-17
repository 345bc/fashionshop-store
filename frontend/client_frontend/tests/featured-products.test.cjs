const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const Module = require('node:module');
const ts = require('typescript');
function load(request) {
  const filename = path.resolve(__dirname, '../src/service/featuredProductService.ts');
  const loaded = new Module(filename, module);
  loaded.require = name => { if (name === '@/api/apiClient') return { apiRequest: request }; throw new Error(name); };
  loaded._compile(ts.transpileModule(fs.readFileSync(filename, 'utf8'), { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 } }).outputText, filename);
  return loaded.exports;
}
const card = id => ({ id, slug: 'product-' + id, name: 'Product ' + id, basePrice: 100000, salePrice: 95000, colors: [] });
test('uses real featured API, preserves ranking and forwards abort signal', async () => {
  const signal = new AbortController().signal;
  const products = await load(async (url, options) => {
    assert.equal(url, '/product/featured?size=8'); assert.equal(options.signal, signal); assert.equal(options.cache, 'no-store');
    return { data: { title: 'Featured', description: 'Description', isDisplay: true, products: [{ product: card(9), support: .4 }, { product: card(2), support: .3 }] } };
  }).featuredProducts(signal);
  assert.deepEqual(products.products.map(p => p.id), [9, 2]); assert.equal(products.products[0].salePrice, 95000);
});
test('empty results stay empty and malformed data does not become sample products', async () => {
  assert.deepEqual((await load(async () => ({ data: { title: 'Featured', isDisplay: true, products: [] } })).featuredProducts()).products, []);
  for (const data of [{}, { products: [null] }, { products: [{ product: { ...card(1), basePrice: NaN } }] }])
    await assert.rejects(load(async () => ({ data })).featuredProducts());
});

test('admin display setting hides products while retaining configured heading', async () => {
  const data = await load(async () => ({ data: { title: 'Khách hàng lựa chọn', description: 'Nội dung đã sửa', isDisplay: false, products: [{ product: card(1) }] } })).featuredProducts();
  assert.deepEqual(data.products, []); assert.equal(data.title, 'Khách hàng lựa chọn'); assert.equal(data.description, 'Nội dung đã sửa');
});
