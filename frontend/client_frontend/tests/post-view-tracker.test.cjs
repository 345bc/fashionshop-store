const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const Module = require('node:module');
const ts = require('typescript');
const flush = () => new Promise(setImmediate);
function load(service) {
  const filename = path.resolve(__dirname, '../src/service/postViewTracker.ts');
  const loaded = new Module(filename, module);
  loaded.require = name => { if (name === './postService') return service; throw new Error(name); };
  loaded._compile(ts.transpileModule(fs.readFileSync(filename, 'utf8'), { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 } }).outputText, filename);
  return loaded.exports;
}
class PostRequestError extends Error { constructor(message, status) { super(message); this.status = status; } }
async function setup(t, record) {
  t.mock.timers.enable({ apis: ['setTimeout'] });
  class Page extends EventTarget { visibilityState = 'visible'; }
  const page = new Page(); let time = 0; const calls = []; const updates = [];
  const service = {
    startPostView: async () => ({ token: 'server-issued-token', minimumSeconds: 10 }),
    recordPostView: async (...args) => { calls.push(args); return record ? record(...args) : { counted: true, viewCount: 8 }; },
    isPostAbort: e => e?.name === 'AbortError', PostRequestError,
  };
  const stop = load(service).trackPostView('bai-viet', n => updates.push(n), page, () => time);
  await flush();
  return { page, calls, updates, stop, advance: async ms => { time += ms; t.mock.timers.tick(ms); await flush(); },
    visibility: state => { page.visibilityState = state; page.dispatchEvent(new Event('visibilitychange')); } };
}
test('does not count before ten seconds; sends one server token after ten', async t => {
  const h = await setup(t); await h.advance(9999); assert.equal(h.calls.length, 0);
  await h.advance(1); assert.equal(h.calls.length, 1); assert.deepEqual(h.calls[0].slice(0,2), ['bai-viet', 'server-issued-token']);
  assert.deepEqual(h.updates, [8]); await h.advance(600000); assert.equal(h.calls.length, 1); h.stop();
});
test('hidden tabs pause the timer and resume the remaining visible time', async t => {
  const h = await setup(t); await h.advance(4000); h.visibility('hidden');
  await h.advance(60000); assert.equal(h.calls.length, 0);
  h.visibility('visible'); await h.advance(5999); assert.equal(h.calls.length, 0);
  await h.advance(1); assert.equal(h.calls.length, 1); h.stop();
});
test('leaving the article cancels its pending timer and request signal', async t => {
  const h = await setup(t); await h.advance(9000); h.stop(); await h.advance(60000); assert.equal(h.calls.length, 0);
});
test('initially hidden article only starts its dwell timer when visible', async t => {
  t.mock.timers.enable({ apis: ['setTimeout'] });
  class Page extends EventTarget { visibilityState = 'hidden'; }
  const page = new Page(); let time = 0; let calls = 0;
  const stop = load({ startPostView: async () => ({ token: 'token', minimumSeconds: 10 }), recordPostView: async () => { calls++; return { counted: true, viewCount: 1 }; }, isPostAbort: () => false, PostRequestError }).trackPostView('a', () => {}, page, () => time);
  await flush(); time += 20000; t.mock.timers.tick(20000); await flush(); assert.equal(calls, 0);
  page.visibilityState = 'visible'; page.dispatchEvent(new Event('visibilitychange'));
  time += 10000; t.mock.timers.tick(10000); await flush(); assert.equal(calls, 1); stop();
});
test('server duplicate response updates displayed count without optimistic increment', async t => {
  const h = await setup(t, async () => ({ counted: false, viewCount: 7 }));
  await h.advance(10000); assert.deepEqual(h.updates, [7]); assert.equal(h.calls.length, 1); h.stop();
});
test('transient submission failure retries the same token', async t => {
  let attempts = 0;
  const h = await setup(t, async () => { if (++attempts === 1) throw new Error('network'); return { counted: true, viewCount: 8 }; });
  await h.advance(10000); assert.equal(h.calls.length, 1); assert.deepEqual(h.updates, []);
  await h.advance(2000); await h.advance(0); assert.equal(h.calls.length, 2); assert.equal(h.calls[0][1], h.calls[1][1]); h.stop();
});
