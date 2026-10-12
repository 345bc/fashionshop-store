const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const Module = require('node:module');
const ts = require('typescript');
const { NextRequest } = require('next/server');

process.env.WORKFLOW_COOKIE_SECRET = 'test-only-workflow-secret-at-least-32-characters';
function load(relative) {
  const filename = path.resolve(__dirname, '..', relative);
  const loaded = new Module(filename, module);
  loaded.paths = Module._nodeModulePaths(path.dirname(filename));
  const originalRequire = loaded.require.bind(loaded);
  loaded.require = name => name === '@/utils/server/workflowCookie' ? cookie : originalRequire(name);
  const output = ts.transpileModule(fs.readFileSync(filename, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
  }).outputText;
  loaded._compile(output, filename);
  return loaded.exports;
}
const cookie = load('src/utils/server/workflowCookie.ts');
const { proxy } = load('src/proxy.ts');
const flow = load('src/app/api/checkout-flow/route.ts');
function request(route, options = {}) {
  return new NextRequest(`http://localhost:3000${route}`, options);
}
function post(body, token = cookie.signWorkflow('checkout')) {
  return request('/api/checkout-flow', { method: 'POST', headers: {
    Origin: 'http://localhost:3000', 'Content-Type': 'application/json', Cookie: `${cookie.WORKFLOW_COOKIE}=${token}`,
  }, body: JSON.stringify(body) });
}
async function withFetch(fake, work) {
  const previous = global.fetch;
  global.fetch = fake;
  try { await work(); } finally { global.fetch = previous; }
}

test('forged old cookie cannot enter checkout; signed flow can', async () => {
  const denied = await proxy(request('/checkout', { headers: { Cookie: 'checkout_allowed=true' } }));
  assert.equal(denied.status, 307);
  assert.equal(new URL(denied.headers.get('location')).pathname, '/products');
  const allowed = await proxy(request('/checkout', { headers: { Cookie: `${cookie.WORKFLOW_COOKIE}=${cookie.signWorkflow('checkout')}` } }));
  assert.equal(allowed.headers.get('x-middleware-next'), '1');
});

test('tampered and expired cookies are rejected', () => {
  const signed = cookie.signWorkflow('checkout');
  const [payload, signature] = signed.split('.');
  const altered = Buffer.from(JSON.stringify({ phase: 'paid', expiresAt: Date.now() + 3600000 })).toString('base64url');
  assert.equal(cookie.verifyWorkflow(`${altered}.${signature}`), null);
  assert.equal(cookie.verifyWorkflow(`${payload}.invalid`), null);
  const previous = Date.now;
  Date.now = () => previous() + 7200000;
  try { assert.equal(cookie.verifyWorkflow(signed), null); } finally { Date.now = previous; }
});

test('checkout phase cannot open success page', async () => {
  const response = await proxy(request('/order-success', { headers: { Cookie: `${cookie.WORKFLOW_COOKIE}=${cookie.signWorkflow('checkout')}` } }));
  assert.equal(response.status, 307);
});

test('forged authentication cookie is checked against backend', async () => {
  await withFetch(async () => new Response('{}', { status: 401 }), async () => {
    const response = await proxy(request('/profile', { headers: { Cookie: 'ACCESS_TOKEN=fake' } }));
    assert.equal(response.status, 307);
    assert.equal(new URL(response.headers.get('location')).pathname, '/login');
  });
});

test('backend failure does not allow protected account pages', async () => {
  await withFetch(async () => { throw new Error('Offline'); }, async () => {
    assert.equal((await proxy(request('/orders', { headers: { Cookie: 'ACCESS_TOKEN=test' } }))).status, 503);
  });
});

test('expired access cookie can renew a protected page using refresh cookie and CSRF', async () => {
  let calls = 0;
  await withFetch(async (url, options) => {
    if (++calls === 1) {
      assert.ok(url.endsWith('/auth/csrf'));
      return Response.json({ data: { headerName: 'X-XSRF-TOKEN', token: 'csrf-renew' } }, { headers: { 'Set-Cookie': 'XSRF-TOKEN=csrf-renew; Path=/' } });
    }
    assert.ok(url.endsWith('/auth/refresh'));
    assert.equal(options.method, 'POST');
    assert.equal(options.headers['X-XSRF-TOKEN'], 'csrf-renew');
    assert.ok(options.headers.Cookie.includes('REFRESH_TOKEN=refresh-session'));
    assert.ok(options.headers.Cookie.includes('XSRF-TOKEN=csrf-renew'));
    const headers = new Headers();
    headers.append('Set-Cookie', 'ACCESS_TOKEN=renewed; Path=/; HttpOnly');
    headers.append('Set-Cookie', 'REFRESH_TOKEN=rotated; Path=/; HttpOnly');
    return Response.json({ data: { id: 12 } }, { headers });
  }, async () => {
    const response = await proxy(request('/orders', { headers: { Cookie: 'REFRESH_TOKEN=refresh-session' } }));
    assert.equal(response.headers.get('x-middleware-next'), '1');
    assert.ok(response.headers.getSetCookie().some(value => value.startsWith('ACCESS_TOKEN=renewed')));
    assert.ok(response.headers.getSetCookie().some(value => value.startsWith('REFRESH_TOKEN=rotated')));
  });
  assert.equal(calls, 2);
});

test('forged refresh cannot bypass protected pages', async () => {
  await withFetch(async url => url.endsWith('/auth/csrf')
    ? Response.json({ data: { headerName: 'X-XSRF-TOKEN', token: 'csrf' } })
    : Response.json({ message: 'Invalid refresh' }, { status: 401 }), async () => {
    const response = await proxy(request('/profile', { headers: { Cookie: 'REFRESH_TOKEN=forged' } }));
    assert.equal(response.status, 307);
    assert.equal(new URL(response.headers.get('location')).pathname, '/login');
    assert.equal(response.cookies.get('REFRESH_TOKEN').value, '');
  });
});

test('cross-origin and empty-cart requests cannot create flow cookies', async () => {
  const crossOrigin = request('/api/checkout-flow', { method: 'POST', headers: { Origin: 'https://other.example' }, body: '{}' });
  assert.equal((await flow.POST(crossOrigin)).status, 403);
  const empty = await flow.POST(post({ phase: 'checkout', items: [] }));
  assert.equal(empty.status, 400);
  assert.equal(empty.cookies.get(cookie.WORKFLOW_COOKIE), undefined);
});

test('server quote must permit products before checkout cookie is issued', async () => {
  let calls = 0;
  await withFetch(async (_url, options) => {
    if (++calls === 1) return Response.json({ data: { headerName: 'X-XSRF-TOKEN', token: 'csrf-test' } }, { headers: { 'Set-Cookie': 'XSRF-TOKEN=csrf-test; Path=/' } });
    assert.equal(options.headers.Cookie, 'XSRF-TOKEN=csrf-test');
    return Response.json({ data: { items: [{ purchasable: false }] } });
  }, async () => {
    const response = await flow.POST(post({ phase: 'checkout', items: [{ variantId: 1, quantity: 1 }] }));
    assert.equal(response.status, 409);
    assert.equal(response.cookies.get(cookie.WORKFLOW_COOKIE), undefined);
  });
});

test('only backend-confirmed paid order can issue success cookie', async () => {
  const body = { phase: 'paid', code: `ORD-${'A'.repeat(28)}`, checkoutToken: 'capability' };
  await withFetch(async () => Response.json({ data: { status: 'PENDING', paymentStatus: 'PENDING' } }), async () => {
    assert.equal((await flow.POST(post(body))).status, 409);
  });
  await withFetch(async (_url, options) => {
    assert.equal(options.headers['X-Checkout-Token'], 'capability');
    return Response.json({ data: { status: 'CONFIRMED', paymentStatus: 'PAID' } });
  }, async () => {
    const response = await flow.POST(post(body));
    assert.equal(response.status, 200);
    const issued = response.cookies.get(cookie.WORKFLOW_COOKIE);
    assert.equal(cookie.verifyWorkflow(issued.value).phase, 'paid');
    assert.equal(issued.httpOnly, true);
  });
});
