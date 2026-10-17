const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const Module = require('node:module');
const ts = require('typescript');
const React = require('react');
const { renderToStaticMarkup } = require('react-dom/server');
const filename = path.resolve(__dirname, '../src/components/PostContent.tsx');
const loaded = new Module(filename, module);
loaded.paths = Module._nodeModulePaths(path.dirname(filename));
const originalRequire = loaded.require.bind(loaded);
loaded.require = name => name.endsWith('.css') ? { content: 'content' } : originalRequire(name);
loaded._compile(ts.transpileModule(fs.readFileSync(filename, 'utf8'), { compilerOptions: {
  module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022, jsx: ts.JsxEmit.ReactJSX,
  esModuleInterop: true,
} }).outputText, filename);
const Content = loaded.exports.default;
const render = ops => renderToStaticMarkup(React.createElement(Content, { content: 'zella-quill-v1:' + JSON.stringify(ops) }));
test('legacy content renders as text, escaping HTML', () => {
  const html = renderToStaticMarkup(React.createElement(Content, { content: '<script>alert(1)</script>\nBài cũ' }));
  assert.ok(html.includes('&lt;script&gt;')); assert.ok(!html.includes('<script>'));
});
test('renders headings, inline formats, quotes and consecutive list items', () => {
  const html = render([
    { insert: 'Tiêu đề' }, { insert: '\n', attributes: { header: 2 } },
    { insert: 'Đậm', attributes: { bold: true, italic: true, underline: true } }, { insert: '\n' },
    { insert: 'Một' }, { insert: '\n', attributes: { list: 'ordered' } },
    { insert: 'Hai' }, { insert: '\n', attributes: { list: 'ordered' } },
    { insert: 'Trích dẫn' }, { insert: '\n', attributes: { blockquote: true } },
  ]);
  assert.match(html, /<h2>Tiêu đề<\/h2>/); assert.match(html, /<u><em><strong>Đậm/);
  assert.match(html, /<ol><li>Một<\/li><li>Hai<\/li><\/ol>/);
  assert.match(html, /<blockquote>Trích dẫn/);
});
test('cloud image and safe link render, executable URLs do not', () => {
  const html = render([
    { insert: 'An toàn', attributes: { link: 'https://example.com' } },
    { insert: 'Xấu', attributes: { link: 'javascript:alert(1)' } },
    { insert: { image: 'https://cloud.example/photo.png' } },
    { insert: { image: 'data:image/svg+xml,evil' } }, { insert: '\n' },
  ]);
  assert.ok(html.includes('href="https://example.com/"'));
  assert.ok(html.includes('src="https://cloud.example/photo.png"'));
  assert.ok(!html.includes('javascript:')); assert.ok(!html.includes('data:image'));
});
test('malformed stored rich content has readable error', () => {
  const html = renderToStaticMarkup(React.createElement(Content, { content: 'zella-quill-v1:broken' }));
  assert.ok(html.includes('role="alert"'));
});
