const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const Module = require('node:module');
const ts = require('typescript');
class ApiClientError extends Error { constructor(message, status) { super(message); this.status = status; } }
function load(request) {
  const filename = path.resolve(__dirname, '../src/service/postService.ts');
  const loaded = new Module(filename, module);
  loaded.paths = Module._nodeModulePaths(path.dirname(filename));
  loaded.require = name => { if (name === '@/api/apiClient') return { apiRequest: request, ApiClientError, reportConnectionFailure: () => {} }; throw new Error(name); };
  loaded._compile(ts.transpileModule(fs.readFileSync(filename, 'utf8'), { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 } }).outputText, filename);
  return loaded.exports;
}
const page = (content = [], number = 0, totalElements = content.length) => ({ content, number, size: 12, totalElements, totalPages: Math.ceil(totalElements / 12) });
test('search, category and server pagination are encoded in API query', async () => {
  let url, options;
  const service = load(async (path, opts) => { url = path; options = opts; return { data: page([], 3, 42) }; });
  const result = await service.listPosts('  áo & đầm  ', '7', 3, 12);
  const params = new URL('https://example.com' + url).searchParams;
  assert.equal(params.get('q'), 'áo & đầm'); assert.equal(params.get('categoryId'), '7'); assert.equal(params.get('page'), '3');
  assert.equal(result.totalElements, 42); assert.equal(options.cache, 'no-store'); assert.ok(options.signal);
});
test('empty backend data stays empty and inactive categories are omitted', async () => {
  const service = load(async path => ({ data: path === '/posts/categories' ? [{ id: 1, active: true }, { id: 2, active: false }] : page() }));
  assert.deepEqual((await service.listPosts()).content, []);
  assert.deepEqual((await service.postCategories()).map(c => c.id), [1]);
});
test('rejects malformed success payload rather than silently showing sample content', async () => {
  await assert.rejects(load(async () => ({ data: null })).listPosts(), /không hợp lệ/);
  await assert.rejects(load(async () => ({ data: { content: [] } })).listPosts(), /không hợp lệ/);
  await assert.rejects(load(async () => ({ data: {} })).postCategories(), /không hợp lệ/);
});
test('missing post remains 404 and network failure has a readable error', async () => {
  const missing = load(async () => { throw new ApiClientError('Missing', 404); });
  await assert.rejects(missing.readPost('bai-da-an'), e => e.status === 404 && /được ẩn/.test(e.message));
  await assert.rejects(load(async () => { throw new TypeError('fetch failed'); }).listPosts(), /Không kết nối/);
});
test('cancels obsolete requests and distinguishes cancellation from errors', async () => {
  const service = load((path, { signal }) => new Promise((resolve, reject) => signal.addEventListener('abort', () => reject(new DOMException('aborted', 'AbortError')))));
  const controller = new AbortController();
  const promise = service.listPosts('a', '', 0, 12, controller.signal);
  controller.abort();
  await assert.rejects(promise, service.isPostAbort);
});
test('request timeout ends loading with retryable error', async t => {
  t.mock.timers.enable({ apis: ['setTimeout'] });
  const service = load((path, { signal }) => new Promise((resolve, reject) => signal.addEventListener('abort', () => reject(new DOMException('aborted', 'AbortError')))));
  const promise = service.listPosts();
  t.mock.timers.tick(15001);
  await assert.rejects(promise, /phản hồi quá lâu/);
  t.mock.timers.reset();
});
test('overview loads each category independently, beyond latest five posts', async () => {
  const paths = [];
  const cats = [{ id: 1, name: 'One', active: true, thumbnail: 'https://cloud.example/category.png' }, { id: 2, name: 'Two', active: true }];
  const service = load(async path => {
    paths.push(path);
    if (path === '/posts/categories') return { data: cats };
    const params = new URL('https://example.com' + path).searchParams;
    if (params.get('categoryId') === '2') throw new Error('offline');
    return { data: page([{ id: 10, thumbnail: 'https://cloud.example/cover.png' }]) };
  });
  const data = await service.loadPostJournal();
  assert.equal(data.posts.length, 1); assert.equal(data.sections[0].posts.length, 1);
  assert.equal(data.sections[0].image, 'https://cloud.example/category.png');
  assert.ok(data.sections[1].error); assert.equal(data.sections[1].posts.length, 0);
  assert.ok(paths.some(p => p.includes('categoryId=2')));
});
test('overview category failure does not discard latest articles', async () => {
  const service = load(async path => { if (path === '/posts/categories') throw new Error('offline'); return { data: page([{ id: 1 }]) }; });
  const data = await service.loadPostJournal();
  assert.equal(data.posts.length, 1); assert.ok(data.categoriesError); assert.deepEqual(data.sections, []);
});

test('view session and recording use POST with server-issued token', async () => {
  const calls = [];
  const service = load(async (path, options) => { calls.push([path, options]); return { data: path.endsWith('/view-session') ? { token: 'token', minimumSeconds: 10 } : { counted: true, viewCount: 9 } }; });
  const session = await service.startPostView('áo mới');
  await service.recordPostView('áo mới', session.token);
  assert.ok(calls[0][0].endsWith('/view-session')); assert.equal(calls[0][1].method, 'POST');
  assert.equal(calls[1][1].method, 'POST'); assert.deepEqual(calls[1][1].body, { token: 'token' });
});
test('recommendations are provided by backend instead of slicing newest articles', async () => {
  const service = load(async path => ({ data: path === '/posts/recommendations' ? [{ id: 2 }, { id: 3 }, { id: 8 }, { id: 5 }] : path === '/posts/categories' ? [] : page([{ id: 1 }]) }));
  const result = await service.loadPostJournal();
  assert.deepEqual(result.recommendations.map(p => p.id), [2,3,8,5]); assert.equal(result.posts[0].id, 1);
});

test('category recommendations carry category scope to backend', async () => {
  let requested;
  const service = load(async path => { requested = path; return { data: [] }; });
  await service.recommendedPosts(undefined, 7);
  assert.equal(requested, '/posts/recommendations?categoryId=7');
});

test('homepage requests most viewed article using lifetime views', async () => {
  let requested;
  const service = load(async path => { requested = path; return { data: [{ id: 8, viewCount: 900, weeklyViewCount: 12 }] }; });
  const result = await service.popularPosts();
  assert.equal(requested, '/posts/popular');
  assert.equal(result[0].viewCount, 900);
});
test('popular empty state stays empty and invalid view count is rejected', async () => {
  assert.deepEqual(await load(async () => ({ data: [] })).popularPosts(), []);
  await assert.rejects(load(async () => ({ data: [{ id: 1 }] })).popularPosts(), /không hợp lệ/);
  await assert.rejects(load(async () => ({ data: [{ id: 1, viewCount: 0 }] })).popularPosts(), /không hợp lệ/);
});

test('article sidebar requests a bounded popular list while homepage keeps its existing API', async () => {
  const urls = [];
  const service = load(async url => { urls.push(url); return { data: [] }; });
  await service.popularPosts(); await service.popularPosts(undefined, 4); await service.popularPosts(undefined, 100);
  assert.deepEqual(urls, ['/posts/popular', '/posts/popular?size=4', '/posts/popular?size=5']);
});
