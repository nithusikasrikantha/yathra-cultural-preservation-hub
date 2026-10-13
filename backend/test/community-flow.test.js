const { test } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const memberships = new Map();
const stories = [];
const stub = (path, exports) => { require.cache[require.resolve(path)] = { id: require.resolve(path), filename: require.resolve(path), loaded: true, exports }; };
stub('../src/middleware/authenticate', (req, res, next) => {
  if (!req.get('x-user')) return res.status(401).json({ message: 'Authentication required.' });
  req.user = { _id: req.get('x-user'), role: req.get('x-role') || 'elder' };
  next();
});
stub('../src/models/CommunityMembership', {
  aggregate: async () => [...new Set([...memberships.values()].map(m => m.communityId))].map(id => ({ _id: id, count: [...memberships.values()].filter(m => m.communityId === id).length })),
  find: ({ user }) => ({ lean: async () => [...memberships.values()].filter(m => m.user === user) }),
  exists: async ({ user, communityId }) => memberships.has(`${user}:${communityId}`),
  updateOne: async (filter) => memberships.set(`${filter.user}:${filter.communityId}`, filter),
  deleteOne: async (filter) => memberships.delete(`${filter.user}:${filter.communityId}`),
  countDocuments: async ({ communityId }) => [...memberships.values()].filter(m => m.communityId === communityId).length,
});
function matches(story, filter) {
  return Object.entries(filter).every(([key, value]) => {
    if (key === '$or') return value.some(part => matches(story, part));
    if (value instanceof RegExp) return value.test(story[key]);
    if (value?.$in) return value.$in.some(item => item instanceof RegExp ? item.test(story[key]) : item === story[key]);
    return story[key] === value;
  });
}
class Story {
  constructor(fields) { Object.assign(this, fields); this._id = String(stories.length + 1).padStart(24, '0'); }
  async save() { if (!stories.includes(this)) stories.push(this); return this; }
  async populate() { return this; }
  static find(filter) {
    let offset = 0, limit = 20;
    const query = { populate: () => query, sort: () => query, skip: n => { offset = n; return query; }, limit: n => { limit = n; return query; }, then: (resolve, reject) => Promise.resolve(stories.filter(s => matches(s, filter)).slice(offset, offset + limit)).then(resolve, reject) };
    return query;
  }
  static async countDocuments(filter) { return stories.filter(s => matches(s, filter)).length; }
  static async findOne(filter) { return stories.find(s => matches(s, filter)); }
}
stub('../src/models/Story', Story);
const app = express();
app.use(express.json());
app.use('/api/communities', require('../src/routes/communityRoutes'));
app.use('/api/stories', require('../src/routes/storyRoutes'));

test('community following and story publication flow', async t => {
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  t.after(() => server.close());
  const base = `http://127.0.0.1:${server.address().port}`;
  async function request(path, { user = 'elder-a', role = 'elder', method = 'GET', body } = {}) {
    const response = await fetch(`${base}${path}`, { method, headers: { 'Content-Type': 'application/json', ...(user ? { 'x-user': user, 'x-role': role } : {}) }, body: body ? JSON.stringify(body) : undefined });
    return { status: response.status, data: await response.json() };
  }
  const draft = { title: 'Family recipe', category: 'Recipe', language: 'Tamil', storyText: 'Original words from an elder.', communityId: 'jaffna_cuisine', aiSummary: 'A family recipe passed down through generations.', summaryStatus: 'approved' };
  await t.test('requires authenticated following and valid communities', async () => {
    assert.equal((await request('/api/stories?following=true', { user: '' })).status, 401);
    assert.equal((await request('/api/communities/missing/follow', { method: 'PUT', body: { follow: true } })).status, 404);
    assert.equal((await request('/api/stories', { method: 'POST', body: draft })).status, 400);
  });
  await t.test('duplicate follows remain one membership and counts survive reload', async () => {
    for (let i = 0; i < 2; i++) assert.equal((await request('/api/communities/jaffna_cuisine/follow', { method: 'PUT', body: { follow: true } })).data.membersCount, 1);
    const mine = (await request('/api/communities')).data.items.find(c => c.id === 'jaffna_cuisine');
    assert.equal(mine.isFollowing, true); assert.equal(mine.membersCount, 1);
    assert.equal((await request('/api/communities', { user: 'youth-b' })).data.items.find(c => c.id === 'jaffna_cuisine').isFollowing, false);
  });
  await t.test('publishes approved preview separately from original', async () => {
    const result = await request('/api/stories', { method: 'POST', body: draft });
    assert.equal(result.status, 201); assert.equal(result.data.story.storyText, draft.storyText);
    assert.equal(result.data.story.aiSummary, draft.aiSummary); assert.equal(result.data.story.communityName, 'Traditional Jaffna Cuisine');
    assert.equal((await request('/api/stories', { role: 'youth', method: 'POST', body: draft })).status, 403);
  });
  await t.test('following excludes unfollowed and general posts; category still includes recipes', async () => {
    await request('/api/stories', { method: 'POST', body: { ...draft, communityId: '', summaryStatus: 'skipped' } });
    assert.equal((await request('/api/stories?following=true')).data.items.length, 1);
    assert.equal((await request('/api/stories?following=true', { user: 'youth-b' })).data.items.length, 0);
    assert.equal((await request('/api/stories?category=Food')).data.items.length, 2);
    assert.equal((await request('/api/stories?communityId=jaffna_cuisine')).data.items.length, 1);
  });
  await t.test('changed source invalidates summary; unapproved previews are omitted', async () => {
    const id = stories[0]._id;
    assert.equal((await request(`/api/stories/${id}`, { user: 'other-elder', method: 'PUT', body: { storyText: 'Changed' } })).status, 403);
    const changed = await request(`/api/stories/${id}`, { method: 'PUT', body: { storyText: 'New original text' } });
    assert.equal(changed.data.story.summaryStatus, 'outdated');
    const skipped = await request(`/api/stories/${id}`, { method: 'PUT', body: { aiSummary: 'Unapproved', summaryStatus: 'skipped' } });
    assert.equal(skipped.data.story.aiSummary, null);
  });
  await t.test('unfollow updates counts and following feed', async () => {
    assert.equal((await request('/api/communities/jaffna_cuisine/follow', { method: 'PUT', body: { follow: false } })).data.membersCount, 0);
    assert.equal((await request('/api/stories?following=true')).data.items.length, 0);
  });
});
