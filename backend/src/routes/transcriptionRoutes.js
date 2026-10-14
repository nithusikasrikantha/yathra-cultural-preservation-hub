const express = require('express');
const multer = require('multer');
const authenticate = require('../middleware/authenticate');
const { openaiApiKey } = require('../config/env');

const router = express.Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 24 * 1024 * 1024, files: 1, fields: 2 },
});

router.post('/audio-transcription', authenticate, (req, res, next) => {
  if (!['elder', 'youth'].includes(req.user.role)) {
    return res.status(403).json({ message: 'Story transcription is not available for this account.' });
  }
  upload.single('audio')(req, res, (error) => {
    if (error) return res.status(error.code === 'LIMIT_FILE_SIZE' ? 413 : 400).json({
      message: error.code === 'LIMIT_FILE_SIZE' ? 'Recording is too large. Use a recording smaller than 24 MB.' : 'Upload one audio recording.',
    });
    next();
  });
}, async (req, res) => {
  const languages = { Tamil: 'ta', Sinhala: 'si', English: 'en' };
  if (!req.file || !req.file.size || !/\.m4a$/i.test(req.file.originalname) || !languages[req.body.language]) {
    return res.status(400).json({ message: 'Upload a saved M4A recording and select Tamil, Sinhala, or English.' });
  }
  if (req.user.role === 'youth') {
    const mongoose = require('mongoose');
    const Connection = require('../models/Connection');
    const id = req.body.connectionId;
    if (!mongoose.isValidObjectId(id) || !await Connection.exists({ _id: id, requester: req.user._id, status: 'accepted' })) {
      return res.status(403).json({ message: 'An accepted collaboration is required to transcribe a story.' });
    }
  }
  if (process.env.VOICE_AI_PROVIDER === 'gemini') {
    if (req.file.size > 14 * 1024 * 1024) return res.status(413).json({ message: 'For Gemini conversion, use a recording smaller than 14 MB.' });
    try {
      const { transcribeRecording } = require('../services/geminiVoiceService');
      const text = await transcribeRecording(req.file.buffer, req.body.language);
      if (!text.trim()) return res.status(422).json({ message: 'No speech was found in this recording.' });
      return res.json({ text: text.trim() });
    } catch (error) {
      return res.status(503).json({ message: error.name === 'TimeoutError' ? 'Voice conversion timed out. Try a shorter recording.' : error.message });
    }
  }
  if (!openaiApiKey) return res.status(503).json({ message: 'Voice conversion requires OPENAI_API_KEY in the backend configuration.' });
  try {
    const form = new FormData();
    form.append('file', new Blob([req.file.buffer], { type: 'audio/mp4' }), 'story.m4a');
    form.append('model', process.env.OPENAI_TRANSCRIPTION_MODEL || 'gpt-4o-transcribe');
    form.append('language', languages[req.body.language]);
    form.append('response_format', 'json');
    const response = await fetch('https://api.openai.com/v1/audio/transcriptions', {
      method: 'POST', headers: { Authorization: `Bearer ${openaiApiKey}` },
      body: form, signal: AbortSignal.timeout(90000),
    });
    if (!response.ok) {
      const failure = await response.json().catch(() => ({}));
      const code = failure.error?.code;
      const quotaExceeded = failure.error?.type === 'insufficient_quota' ||
        ['insufficient_quota', 'billing_hard_limit_reached', 'billing_not_active',
          'organization_usage_limit_exceeded', 'usage_limit_reached'].includes(code);
      const message = response.status === 429 ? (quotaExceeded
        ? 'Voice conversion has no available API quota. The backend owner must check OpenAI API billing, credits, and usage limits. Retrying alone will not fix this.'
        : 'Voice conversion reached an API request limit. Wait a minute and try again.')
        : response.status === 401 || response.status === 403 ? 'Voice conversion could not authenticate. Check the backend AI configuration.'
          : response.status === 400 ? 'The recording or transcription model is unsupported. Check the audio and backend configuration.'
            : 'Voice conversion is unavailable. Please retry.';
      return res.status(503).json({ message, code: quotaExceeded ? 'ai_quota_exhausted' : response.status === 429 ? 'ai_rate_limited' : 'ai_unavailable' });
    }
    const result = await response.json();
    if (typeof result.text !== 'string' || !result.text.trim()) {
      return res.status(422).json({ message: 'No speech was found in this recording. Try a clearer recording.' });
    }
    res.json({ text: result.text.trim() });
  } catch (error) {
    res.status(503).json({ message: error.name === 'TimeoutError' ? 'Voice conversion timed out. Try a shorter recording.' : 'Voice conversion failed. Check your connection and retry.' });
  }
});

router.post('/story-speech', authenticate, async (req, res) => {
  const { text, language } = req.body || {};
  if (!['elder', 'youth'].includes(req.user.role)) return res.status(403).json({ message: 'Story reading is unavailable for this account.' });
  if (typeof text !== 'string' || !text.trim() || text.length > 12000 || !['Tamil', 'Sinhala', 'English'].includes(language)) {
    return res.status(400).json({ message: 'Provide story text of up to 12,000 characters and select its language.' });
  }
  try {
    const { readStory } = require('../services/geminiVoiceService');
    const audio = await readStory(text.trim());
    res.set('Cache-Control', 'no-store').type('audio/wav').send(audio);
  } catch (error) {
    res.status(503).json({ message: error.name === 'TimeoutError' ? 'Story reading timed out. Try a shorter text.' : error.message });
  }
});

module.exports = router;
