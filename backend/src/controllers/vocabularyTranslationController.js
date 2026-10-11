const mongoose = require('mongoose');
const Story = require('../models/Story');
const { knownYouthDemoStories } = require('../config/youthDemoStories');
const {
  translateVocabulary,
  VocabularyTranslationProviderError,
} = require('../services/vocabularyTranslationService');

const supportedLanguages = new Set(['Tamil', 'Sinhala', 'English']);
const MAX_TEXT_CHARACTERS = 100;
const MAX_CONTEXT_CHARACTERS = 2500;

const vocabularyTranslationController = async (req, res) => {
  const { demo, storyId, targetLanguage } = req.body || {};
  const text = typeof req.body?.text === 'string' ? req.body.text.trim() : '';

  if (!text) {
    return res.status(400).json({
      message: 'Enter a word or short phrase to translate.',
    });
  }
  if (text.length > MAX_TEXT_CHARACTERS) {
    return res.status(400).json({
      message: 'Words and phrases must be 100 characters or fewer.',
    });
  }
  if (!supportedLanguages.has(targetLanguage)) {
    return res.status(400).json({
      message: 'Target language must be Tamil, Sinhala, or English.',
    });
  }

  try {
    let storyContext;
    if (demo === true) {
      if (typeof storyId !== 'string' || !storyId.trim()) {
        return res.status(400).json({ message: 'A demo story ID is required.' });
      }
      const knownDemoStory = knownYouthDemoStories.get(storyId);
      if (!knownDemoStory) {
        return res.status(404).json({ message: 'Demo story not found.' });
      }
      storyContext = knownDemoStory.storyText;
    } else {
      if (
        typeof storyId !== 'string' ||
        !mongoose.Types.ObjectId.isValid(storyId)
      ) {
        return res.status(400).json({ message: 'A valid story ID is required.' });
      }
      const story = await Story.findOne({ _id: storyId, isDeleted: false });
      if (!story) return res.status(404).json({ message: 'Story not found.' });
      storyContext = story.storyText;
    }

    const result = await translateVocabulary({
      text,
      targetLanguage,
      storyContext: storyContext.slice(0, MAX_CONTEXT_CHARACTERS),
    });

    return res.status(200).json({
      success: true,
      translation: {
        original: text,
        targetLanguage,
        ...result,
      },
    });
  } catch (error) {
    if (error instanceof VocabularyTranslationProviderError) {
      if (error.code === 'timeout') {
        return res.status(504).json({
          message: 'The vocabulary translation is taking too long. Please try again.',
        });
      }
      return res.status(503).json({
        message: 'Vocabulary translation is temporarily unavailable. Please try again later.',
      });
    }

    console.error('Vocabulary translation failed:', error?.name || 'UnknownError');
    return res.status(500).json({
      message: 'The word or phrase could not be translated right now.',
    });
  }
};

module.exports = { vocabularyTranslationController };
