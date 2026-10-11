const mongoose = require('mongoose');
const Story = require('../models/Story');
const { knownYouthDemoStories } = require('../config/youthDemoStories');
const {
  explainCulturalTerm,
  TermExplanationProviderError,
} = require('../services/termExplanationService');

const supportedLanguages = new Set(['Tamil', 'Sinhala', 'English']);
const MAX_TERM_CHARACTERS = 80;
const MAX_CONTEXT_CHARACTERS = 2500;

const termExplanationController = async (req, res) => {
  const { demo, storyId, targetLanguage } = req.body || {};
  const term = typeof req.body?.term === 'string' ? req.body.term.trim() : '';

  if (!term) {
    return res.status(400).json({ message: 'Enter a cultural term to explain.' });
  }
  if (term.length > MAX_TERM_CHARACTERS) {
    return res.status(400).json({
      message: 'Cultural terms must be 80 characters or fewer.',
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

    const result = await explainCulturalTerm({
      term,
      targetLanguage,
      storyContext: storyContext.slice(0, MAX_CONTEXT_CHARACTERS),
    });

    return res.status(200).json({
      success: true,
      explanation: { term, targetLanguage, ...result },
    });
  } catch (error) {
    if (error instanceof TermExplanationProviderError) {
      if (error.code === 'timeout') {
        return res.status(504).json({
          message: 'The explanation is taking too long. Please try again.',
        });
      }
      return res.status(503).json({
        message: 'Cultural term explanations are temporarily unavailable. Please try again later.',
      });
    }

    console.error('Cultural term explanation failed:', error?.name || 'UnknownError');
    return res.status(500).json({
      message: 'The cultural term could not be explained right now.',
    });
  }
};

module.exports = { termExplanationController };
