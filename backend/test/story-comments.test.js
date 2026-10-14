const { test } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const stub = (path, exports) => { const id = require.resolve(path); require.cache[id] = { id, filename: id, loaded: true, exports }; };
const records = [];
stub('../src/middleware/authenticate', (req, res, next) => {
  if (!req.get('x-test-user')) return res.status(401).json({ message: 'Authentication required.' });
  req.user = { _id: '333333333333333333333333', name: 'Test elder' }; next();
});
stub('../src/models/Story', { exists: async () => true });
stub('../src/models/StoryComment', {
  create: async record => { records.push(record); return record; },
  find: filter => ({ sort: () => ({ limit: () => ({ lean: async () => records.filter(r => r.story === filter.story) }) }) }),
});
test('comments persist for the selected story only and require authentication', async t => {
  const app = express(); app.use(express.json()); app.use(require('../src/routes/storyCommentRoutes'));
  const server = app.listen(0); t.after(() => server.close());
  const base = `http://127.0.0.1:${server.address().port}`;
  const first = '111111111111111111111111', second = '222222222222222222222222';
  const post = (text, auth = true) => fetch(`${base}/${first}/comments`, { method: 'POST', headers: { 'Content-Type': 'application/json', ...(auth ? { 'x-test-user': '1' } : {}) }, body: JSON.stringify({ text }) });
  assert.equal((await post('Memory', false)).status, 401);
  assert.equal((await post('')).status, 400);
  assert.equal((await post('My own memory')).status, 201);
  const own = await (await fetch(`${base}/${first}/comments`)).json();
  assert.equal(own.comments[0].text, 'My own memory');
  assert.equal(own.comments[0].authorName, 'Test elder');
  assert.deepEqual((await (await fetch(`${base}/${second}/comments`)).json()).comments, []);
  assert.equal((await fetch(`${base}/bad/comments`)).status, 400);
});
