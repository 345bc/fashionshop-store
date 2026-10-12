const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const Module = require('node:module');
const ts = require('typescript');

function client() {
  const filename = path.resolve(__dirname, '../src/api/apiClient.js');
  const loaded = new Module(filename, module);
  loaded.paths = Module._nodeModulePaths(path.dirname(filename));
  loaded._compile(ts.transpileModule(fs.readFileSync(filename, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
  }).outputText, filename);
  return loaded.exports;
}
async function withFetch(fake, work) {
  const previous = global.fetch; global.fetch = fake;
  try { await work(); } finally { global.fetch = previous; }
}
const csrf = () => Response.json({ data: { headerName: 'X-XSRF-TOKEN', token: 'csrf-test' } });

test('simultaneous 401 requests share one refresh and retry once', async () => {
  const api = client(); let renewed = false; let refreshes = 0;
  const calls = new Map();
  await withFetch(async (url, options) => {
    const route = new URL(url).pathname;
    if (route.endsWith('/auth/csrf')) return csrf();
    if (route.endsWith('/auth/refresh')) {
      refreshes++; assert.equal(options.method, 'POST');
      assert.equal(options.headers['X-XSRF-TOKEN'], 'csrf-test');
      await new Promise(resolve => setTimeout(resolve, 10)); renewed = true;
      return Response.json({ data: { id: 1 } });
    }
    calls.set(route, (calls.get(route) ?? 0) + 1);
    return renewed ? Response.json({ data: route }) : Response.json({}, { status: 401 });
  }, async () => {
    const values = await Promise.all([api.apiRequest('/me/orders'), api.apiRequest('/me/loyalty')]);
    assert.equal(values.length, 2);
  });
  assert.equal(refreshes, 1); assert.deepEqual([...calls.values()], [2, 2]);
});

test('a mutation rejected before authentication retries with the same body', async () => {
  const api = client(); let calls = 0;
  await withFetch(async (url, options) => {
    if (url.endsWith('/auth/csrf')) return csrf();
    if (url.endsWith('/auth/refresh')) return Response.json({ data: { id: 1 } });
    assert.equal(options.body, JSON.stringify({ rating: 4, comment: 'Test' }));
    assert.equal(options.headers.get('X-XSRF-TOKEN'), 'csrf-test');
    return ++calls === 1 ? Response.json({}, { status: 401 }) : Response.json({ data: 'saved' });
  }, async () => {
    assert.equal((await api.apiRequest('/me/orders/1/items/1/review', { method: 'PUT', body: { rating: 4, comment: 'Test' } })).data, 'saved');
  });
  assert.equal(calls, 2);
});

test('invalid refresh ends retry; authorization errors never refresh', async () => {
  for (const status of [401, 403]) {
    const api = client(); let refreshes = 0;
    await withFetch(async url => {
      if (url.endsWith('/auth/csrf')) return csrf();
      if (url.endsWith('/auth/refresh')) { refreshes++; return Response.json({}, { status: 401 }); }
      return Response.json({ message: 'Denied' }, { status });
    }, async () => {
      await assert.rejects(api.apiRequest('/me/orders'), error => error.status === status);
    });
    assert.equal(refreshes, status === 401 ? 1 : 0);
  }
});

test('backend failure during refresh is reported instead of treated as logout', async () => {
  const api = client();
  await withFetch(async url => {
    if (url.endsWith('/auth/csrf')) return csrf();
    if (url.endsWith('/auth/refresh')) return Response.json({ message: 'Unavailable' }, { status: 503 });
    return Response.json({}, { status: 401 });
  }, async () => {
    await assert.rejects(api.apiRequest('/auth/me'), error => error.status === 503);
  });
});

test('login and logout do not try to refresh rejected requests', async () => {
  const api = client(); let refreshes = 0;
  await withFetch(async url => {
    if (url.endsWith('/auth/csrf')) return csrf();
    if (url.endsWith('/auth/refresh')) refreshes++;
    return Response.json({}, { status: 401 });
  }, async () => {
    await assert.rejects(api.apiRequest('/auth/login', { method: 'POST' }));
    await assert.rejects(api.apiRequest('/auth/logout', { method: 'POST' }));
  });
  assert.equal(refreshes, 0);
});

test('logout waits for an in-flight refresh before clearing the session', async () => {
  const api = client(); const events = [];
  let release; let started;
  const ready = new Promise(resolve => { started = resolve; });
  const gate = new Promise(resolve => { release = resolve; });
  let renewed = false;
  await withFetch(async url => {
    if (url.endsWith('/auth/csrf')) return csrf();
    if (url.endsWith('/auth/refresh')) {
      started(); await gate; renewed = true; events.push('refresh');
      return Response.json({ data: { id: 1 } });
    }
    if (url.endsWith('/auth/logout')) { events.push('logout'); return Response.json({ data: null }); }
    return renewed ? Response.json({ data: { id: 1 } }) : Response.json({}, { status: 401 });
  }, async () => {
    const request = api.apiRequest('/auth/me'); await ready;
    const logout = api.apiRequest('/auth/logout', { method: 'POST' }); release();
    await Promise.all([request, logout]);
  });
  assert.deepEqual(events, ['refresh', 'logout']);
});
