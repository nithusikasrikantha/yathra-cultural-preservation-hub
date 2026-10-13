const { test } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const stub = (path, exports) => { const id = require.resolve(path); require.cache[id] = { id, filename: id, loaded: true, exports }; };
const user = { _id: '111111111111111111111111', role: 'elder', name: 'Author', profileInfo: { avatar: 'https://example.org/avatar.jpg', interests: ['History'] }, save: async () => {} };
stub('../src/middleware/authMiddleware', { requireAuth: (req, res, next) => { if (!req.get('x-user')) return res.status(401).json({ message: 'Authentication required.' }); req.user = user; next(); }, requireYouth: (req, res, next) => next() });
let storyFilter, connectionFilter;
stub('../src/models/Story', { countDocuments: async filter => { storyFilter = filter; return 3; } });
stub('../src/models/Connection', { countDocuments: async filter => { connectionFilter = filter; return 2; } });
test('elder profile edits persist and profile counts use ownership and accepted connections', async t => {
 const app = express(); app.use(express.json()); app.use('/auth', require('../src/routes/authRoutes'));
 const server = app.listen(0); t.after(() => server.close());
 async function call(path, body, authenticated = true) { const response = await fetch(`http://127.0.0.1:${server.address().port}/auth/${path}`, { method: body ? 'PUT' : 'GET', headers: { 'content-type': 'application/json', ...(authenticated ? { 'x-user': user._id } : {}) }, body: body ? JSON.stringify(body) : undefined }); return { status: response.status, data: await response.json() }; }
 assert.equal((await call('elder-profile', undefined, false)).status, 401);
 assert.equal((await call('elder-profile', { name: '', preferredLanguage: 'Tamil' })).status, 400);
 const fields = { name: 'Updated Author', bio: 'Preserving village stories.', location: 'Jaffna', preferredLanguage: 'Tamil' };
 assert.equal((await call('elder-profile', fields)).status, 200);
 const profile = (await call('elder-profile')).data.profile;
 for (const key of Object.keys(fields)) assert.equal(profile[key], fields[key]);
 assert.equal(user.profileInfo.avatar, 'https://example.org/avatar.jpg');
 const stats = (await call('profile-stats')).data;
 assert.deepEqual(stats, { contributions: 3, connections: 2 });
 assert.deepEqual(storyFilter, { isDeleted: false, $or: [{ publishedBy: user._id }, { contributors: user._id }] });
 assert.equal(connectionFilter.status, 'accepted');
 assert.deepEqual(connectionFilter.$or, [{ requester: user._id }, { receiver: user._id }]);
 user.role = 'youth'; assert.equal((await call('elder-profile', fields)).status, 403);
});
