const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const Module = require('node:module');
const ts = require('typescript');
const filename = path.resolve(__dirname, '../src/app/products/page.tsx');
const loaded = new Module(filename, module);
loaded.paths = Module._nodeModulePaths(path.dirname(filename));
loaded.require = name => {
  if (name === 'next/navigation') return { redirect: destination => { throw Object.assign(new Error('redirect'), { destination }); } };
  if (name === 'react/jsx-runtime') return { jsx: () => ({}), jsxs: () => ({}), Fragment: 'fragment' };
  if (name.startsWith('@/components/')) return () => null;
  throw new Error(name);
};
loaded._compile(ts.transpileModule(fs.readFileSync(filename, 'utf8'), {
  compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022, jsx: ts.JsxEmit.ReactJSX },
}).outputText, filename);
const render = params => loaded.exports.default({ searchParams: Promise.resolve(params) });
test('bare catalog and invalid category links redirect home, even with another valid filter', async () => {
  for (const params of [{}, { q: '  ' }, { cat: 'nam' }, { cat: 'nu' }, { cat: '' }, { cat: '0' }, { cat: '-1' }, { cat: '1.5' }, { cat: '9007199254740992' }, { cat: ['1','2'] }, { cat: 'nam', q: 'ao' }, { new: 'false' }, { new: 'true' }, { cat: '12', new: 'true' }]) {
    await assert.rejects(render(params), error => error.destination === '/');
  }
});
test('real category IDs and nonempty search retain catalog access', async () => {
  for (const params of [{ cat: '12' }, { q: '  áo khoác  ' }, { cat: '12', q: 'áo', categoryName: 'Áo nam' }]) {
    await assert.doesNotReject(render(params));
  }
});
