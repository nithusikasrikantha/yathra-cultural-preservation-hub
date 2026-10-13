const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const Story = require('../src/models/Story');
const app = require('../src/app');

test('upload, save, reload, and edit story images', async () => {
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  const originalSave = Story.prototype.save;
  const originalFind = Story.findOne;
  let stored;
  let uploaded;
  Story.prototype.save = async function () { await this.validate(); stored = this.toObject(); return this; };
  Story.findOne = async () => stored ? new Story(stored) : null;
  try {
    const form = new FormData();
    const photo = await fs.readFile(path.join(__dirname, '../../frontend/assets/images/story_landscape.jpg'));
    form.append('image', new Blob([photo], { type: 'image/jpeg' }), 'banner.jpg');
    const upload = await fetch(`${base}/api/images`, { method: 'POST', body: form });
    assert.equal(upload.status, 201);
    uploaded = (await upload.json()).imageUrl;
    assert.equal((await fetch(base + uploaded)).status, 200);
    const request = (url, body, method = 'POST') => fetch(base + url, { method, headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
    const create = await request('/api/stories', { title: 'Harvest', category: 'Traditional Story', language: 'Tamil', storyText: 'Village memories', bannerImage: uploaded, additionalImages: [uploaded], location: 'Jaffna', timePeriod: 'My childhood', community: 'Village' });
    assert.equal(create.status, 201);
    const story = (await create.json()).story;
    const fetched = (await (await fetch(`${base}/api/stories/${story._id}`)).json()).story;
    assert.equal(fetched.bannerImage, uploaded);
    assert.deepEqual(fetched.additionalImages, [uploaded]);
    assert.equal(fetched.location, 'Jaffna');
    const edited = await request(`/api/stories/${story._id}`, { bannerImage: null, additionalImages: [] }, 'PUT');
    assert.equal(edited.status, 200);
    assert.deepEqual((await edited.json()).story.additionalImages, []);
    assert.equal((await request('/api/stories', { additionalImages: Array(9).fill(uploaded) })).status, 400);
    const bad = new FormData();
    bad.append('image', new Blob(['text'], { type: 'text/plain' }), 'bad.txt');
    assert.equal((await fetch(`${base}/api/images`, { method: 'POST', body: bad })).status, 400);
  } finally {
    Story.prototype.save = originalSave;
    Story.findOne = originalFind;
    await new Promise(resolve => server.close(resolve));
    if (uploaded) await fs.unlink(path.join(__dirname, '..', uploaded));
  }
});
