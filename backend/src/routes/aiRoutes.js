const express = require('express');
const { translateStoryController } = require('../controllers/translationController');
const { termExplanationController } = require('../controllers/termExplanationController');
const { vocabularyTranslationController } = require('../controllers/vocabularyTranslationController');
const { requireAuth, requireYouth } = require('../middleware/authMiddleware');
const authenticate = require('../middleware/authenticate');
const { cultureContentAssistantController } = require('../controllers/cultureContentAssistantController');

const router = express.Router();

router.post('/story-translation', requireAuth, requireYouth, translateStoryController);
router.post('/term-explanation', requireAuth, requireYouth, termExplanationController);
router.post('/vocabulary-translation', requireAuth, requireYouth, vocabularyTranslationController);
router.post('/culture-content-assistant/:action', authenticate, cultureContentAssistantController);

module.exports = router;
