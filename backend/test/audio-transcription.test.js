const { test } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const jwt = require('jsonwebtoken');
const env = require('../src/config/env');
env.openaiApiKey = 'test-key';
process.env.VOICE_AI_PROVIDER = 'openai';
const User = require('../src/models/User');
const router = require('../src/routes/transcriptionRoutes');

test('saved audio is forwarded, with auth, validation and provider failures handled', async () => {
  const app = express();
  app.use('/api/ai', router);
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const url = `http://127.0.0.1:${server.address().port}/api/ai/audio-transcription`;
  const originalFind = User.findById;
  const originalFetch = global.fetch;
  User.findById = async () => ({ _id: '507f1f77bcf86cd799439011', role: 'elder' });
  const token = jwt.sign({ sub: '507f1f77bcf86cd799439011' }, env.jwtSecret);
  let providerStatus = 200;
  let providerText = 'My grandmother taught me this song.';
  let calls = 0;
  let providerError;
  global.fetch = async (target, options) => {
    if (target !== 'https://api.openai.com/v1/audio/transcriptions') return originalFetch(target, options);
    calls++;
    assert.equal(options.body.get('language'), 'en');
    assert.equal(await options.body.get('file').text(), 'saved recording bytes');
    return new Response(JSON.stringify({ text: providerText, error: providerError }), { status: providerStatus });
  };
  const request = (language = 'English', filename = 'recording.m4a', authorized = true) => {
    const form = new FormData();
    form.append('language', language);
    form.append('audio', new Blob(['saved recording bytes'], { type: 'audio/mp4' }), filename);
    return originalFetch(url, { method: 'POST', body: form, headers: authorized ? { Authorization: `Bearer ${token}` } : {} });
  };
  try {
    assert.equal((await request('English', 'recording.m4a', false)).status, 401);
    assert.equal((await request('Unknown')).status, 400);
    assert.equal((await request('English', 'recording.txt')).status, 400);
    assert.equal(calls, 0);
    const result = await request();
    assert.equal(result.status, 200);
    assert.equal((await result.json()).text, providerText);
    providerText = '';
    assert.equal((await request()).status, 422);
    providerStatus = 429;
    const failure = await request();
    assert.equal(failure.status, 503);
    assert.equal((await failure.json()).code, 'ai_rate_limited');
    providerError = { code: 'insufficient_quota', type: 'insufficient_quota' };
    const quota = await request();
    const quotaBody = await quota.json();
    assert.equal(quota.status, 503);
    assert.equal(quotaBody.code, 'ai_quota_exhausted');
    assert.match(quotaBody.message, /Retrying alone will not fix/);
  } finally {
    global.fetch = originalFetch;
    User.findById = originalFind;
    await new Promise(resolve => server.close(resolve));
  }
});
