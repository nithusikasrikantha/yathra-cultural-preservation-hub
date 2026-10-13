const express = require('express');
const { translateStoryController } = require('../controllers/translationController');
const { termExplanationController } = require('../controllers/termExplanationController');
const { vocabularyTranslationController } = require('../controllers/vocabularyTranslationController');
const { requireAuth, requireYouth } = require('../middleware/authMiddleware');
const authenticate = require('../middleware/authenticate');
const { cultureContentAssistantController } = require('../controllers/cultureContentAssistantController');

const router = express.Router();

router.post('/story-summary', authenticate, async (req, res) => {
  if (req.user.role !== 'elder') {
    const Connection = require('../models/Connection');
    const mongoose = require('mongoose');
    const id = req.body?.connectionId;
    if (req.user.role !== 'youth' || !mongoose.isValidObjectId(id) || !await Connection.exists({ _id: id, requester: req.user._id, status: 'accepted' })) return res.status(403).json({ message: 'An accepted collaboration is required to generate a story preview.' });
  }
  const { title, storyText, language } = req.body || {};
  if (typeof storyText !== 'string' || !storyText.trim() || storyText.length > 12000 || typeof title !== 'string' || title.length > 180 || !['Tamil', 'Sinhala', 'English'].includes(language)) return res.status(400).json({ message: 'Add a title, language, and story of up to 12,000 characters.' });
  try {
    const { generateCultureContent } = require('../services/cultureContentAssistantService');
    const result = await generateCultureContent({ action: 'story-summary', input: { title, storyText }, language });
    if (typeof result.summary !== 'string' || !result.summary.trim() || result.summary.length > 700) throw new Error('Invalid summary');
    res.json({ summary: result.summary.trim() });
  } catch (_) { res.status(503).json({ message: 'Summary generation is unavailable. Retry or skip the summary to publish your story.' }); }
});
router.post('/story-translation', requireAuth, requireYouth, translateStoryController);
router.post('/term-explanation', requireAuth, requireYouth, termExplanationController);
router.post('/vocabulary-translation', requireAuth, requireYouth, vocabularyTranslationController);
router.post('/culture-content-assistant/:action', authenticate, cultureContentAssistantController);

module.exports = router;
