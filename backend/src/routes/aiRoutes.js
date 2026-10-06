const express = require('express');
const { translateStoryController } = require('../controllers/translationController');
const { requireAuth, requireYouth } = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/story-translation', requireAuth, requireYouth, translateStoryController);

module.exports = router;
