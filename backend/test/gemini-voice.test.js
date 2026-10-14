const { test } = require('node:test');
const assert = require('node:assert/strict');
const { transcribeRecording, readStory } = require('../src/services/geminiVoiceService');

test('Gemini converts saved bytes and returns playable WAV, with failures surfaced', async () => {
  const previousFetch = global.fetch;
  const previousKey = process.env.GEMINI_API_KEY;
  process.env.GEMINI_API_KEY = 'test-only-key';
  let status = 200;
  let calls = 0;
  const wav = Buffer.alloc(46);
  wav.write('RIFF'); wav.write('WAVE', 8);
  global.fetch = async (url, options) => {
    calls++;
    if (status === 503) return new Response(JSON.stringify({ error: { code: 'service_unavailable' } }), { status });
    assert.equal(url, 'https://generativelanguage.googleapis.com/v1beta/interactions');
    assert.equal(options.headers['x-goog-api-key'], 'test-only-key');
    const body = JSON.parse(options.body);
    assert.equal(body.store, false);
    if (body.response_format) {
      assert.equal(body.response_format.mime_type, 'audio/wav');
      assert.equal(body.input[0].content[0].text, 'Family memories');
      return new Response(JSON.stringify({ outputs: [{ type: 'audio', data: wav.toString('base64') }] }), { status });
    }
    assert.equal(Buffer.from(body.input[0].data, 'base64').toString(), 'saved audio');
    assert.equal(body.model, 'gemini-3.5-transcribe');
    return new Response(JSON.stringify({ interaction: { steps: [{ type: 'model_output', content: [{ type: 'text', text: 'Family memories' }] }] } }), { status });
  };
  try {
    assert.equal(await transcribeRecording(Buffer.from('saved audio'), 'Tamil'), 'Family memories');
    assert.deepEqual(await readStory('Family memories'), wav);
    status = 429;
    await assert.rejects(readStory('Family memories'), /Gemini voice quota/);
    const beforeRetries = calls;
    status = 503;
    await assert.rejects(readStory('Family memories'), /HTTP 503, service_unavailable/);
    assert.equal(calls - beforeRetries, 3);
    delete process.env.GEMINI_API_KEY;
    await assert.rejects(readStory('Family memories'), /Add GEMINI_API_KEY/);
  } finally {
    global.fetch = previousFetch;
    if (previousKey === undefined) delete process.env.GEMINI_API_KEY;
    else process.env.GEMINI_API_KEY = previousKey;
  }
});
