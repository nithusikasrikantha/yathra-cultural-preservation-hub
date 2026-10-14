const { test } = require('node:test');
const assert = require('node:assert/strict');
const { generateStorySummary } = require('../src/services/geminiSummaryService');

test('summary uses Gemini, preserves language and rejects invalid previews', async () => {
  const previousFetch = global.fetch;
  const previousKey = process.env.GEMINI_API_KEY;
  process.env.GEMINI_API_KEY = 'test-key';
  let summary = 'A family makes a lantern together.';
  global.fetch = async (url, options) => {
    const body = JSON.parse(options.body);
    assert.equal(body.model, process.env.GEMINI_SUMMARY_MODEL || 'gemini-3.5-flash-lite');
    assert.equal(body.store, false);
    assert.match(body.input[0].text, /Write in English/);
    assert.match(body.input[0].text, /My father taught me/);
    return new Response(JSON.stringify({ interaction: { steps: [{ type: 'model_output', content: [{ type: 'text', text: summary }] }] } }));
  };
  const input = { title: 'Lantern', storyText: 'My father taught me to make a lantern.', language: 'English' };
  try {
    assert.deepEqual(await generateStorySummary(input), { summary });
    summary = 'x'.repeat(701);
    await assert.rejects(generateStorySummary(input), /invalid summary/);
    summary = '';
    await assert.rejects(generateStorySummary(input), /invalid summary/);
  } finally {
    global.fetch = previousFetch;
    if (previousKey === undefined) delete process.env.GEMINI_API_KEY;
    else process.env.GEMINI_API_KEY = previousKey;
  }
});
