const express = require('express');

const {
  getCulturalContent,
} = require('../controllers/culturalContentController');

const router = express.Router();

router.get('/', getCulturalContent);

module.exports = router;
