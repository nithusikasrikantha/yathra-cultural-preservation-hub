const mongoose = require('mongoose');
const Story = require('../models/Story');
const {
  translateStory,
  TranslationProviderError,
} = require('../services/translationService');

const supportedLanguages = new Set(['Tamil', 'Sinhala', 'English']);
const MAX_STORY_CHARACTERS = 12000;
const knownDemoStories = new Map([
  [
    'youth-dummy-village-harvest-festival',
    {
      sourceLanguage: 'English',
      storyText:
        'The story of our village harvest, when the whole community came together to celebrate the season...',
    },
  ],
  [
    'youth-dummy-traditional-jaffna-recipe',
    {
      sourceLanguage: 'English',
      storyText:
        'A traditional recipe passed down through generations, prepared during family and community celebrations...',
    },
  ],
]);

const normalizeLanguage = (language) =>
  typeof language === 'string' ? language.trim().toLowerCase() : '';

const canonicalLanguage = (language) => {
  const normalized = normalizeLanguage(language);
  return [...supportedLanguages].find(
    (supportedLanguage) => normalizeLanguage(supportedLanguage) === normalized
  );
};

const createTranslationResponse = ({
  storyId,
  sourceLanguage,
  targetLanguage,
  translatedText,
}) => ({
  success: true,
  translation: {
    storyId,
    sourceLanguage,
    targetLanguage,
    translatedText,
  },
});

const translateStoryController = async (req, res) => {
  const requestedTargetLanguage = req.body?.targetLanguage;
  const targetLanguage = requestedTargetLanguage === undefined
    ? req.user.profileInfo?.preferredLanguage
    : requestedTargetLanguage;

  if (
    requestedTargetLanguage !== undefined &&
    !supportedLanguages.has(requestedTargetLanguage)
  ) {
    return res.status(400).json({
      message: 'Target language must be Tamil, Sinhala, or English.',
    });
  }
  if (!targetLanguage) {
    return res.status(400).json({
      message: 'Choose a preferred language in your Youth profile before translating stories.',
    });
  }
  if (!supportedLanguages.has(targetLanguage)) {
    return res.status(400).json({
      message: 'Preferred language must be Tamil, Sinhala, or English.',
    });
  }

  try {
    const {
      demo,
      storyId,
      storyText,
      sourceLanguage: requestedSourceLanguage,
    } = req.body || {};

    if (demo === true) {
      if (typeof storyId !== 'string' || !storyId.trim()) {
        return res.status(400).json({ message: 'A demo story ID is required.' });
      }

      const knownDemoStory = knownDemoStories.get(storyId);
      if (!knownDemoStory) {
        return res.status(404).json({ message: 'Demo story not found.' });
      }
      if (typeof storyText !== 'string' || !storyText.trim()) {
        return res.status(400).json({ message: 'Demo story text is required.' });
      }

      const canonicalSourceLanguage = canonicalLanguage(
        requestedSourceLanguage
      );
      if (!canonicalSourceLanguage) {
        return res.status(422).json({
          message: 'Demo story language must be Tamil, Sinhala, or English.',
        });
      }

      if (
        storyText !== knownDemoStory.storyText ||
        canonicalSourceLanguage !== knownDemoStory.sourceLanguage
      ) {
        return res.status(400).json({
          message: 'Demo story content does not match the selected YATHRA story.',
        });
      }
      if (storyText.length > MAX_STORY_CHARACTERS) {
        return res.status(413).json({
          message: 'This story is too long to translate right now.',
        });
      }

      if (
        normalizeLanguage(canonicalSourceLanguage) ===
        normalizeLanguage(targetLanguage)
      ) {
        return res.status(200).json(
          createTranslationResponse({
            storyId,
            sourceLanguage: canonicalSourceLanguage,
            targetLanguage,
            translatedText: storyText,
          })
        );
      }

      const translatedText = await translateStory({
        storyText,
        sourceLanguage: canonicalSourceLanguage,
        targetLanguage,
      });

      return res.status(200).json(
        createTranslationResponse({
          storyId,
          sourceLanguage: canonicalSourceLanguage,
          targetLanguage,
          translatedText,
        })
      );
    }

    if (
      typeof storyId !== 'string' ||
      !mongoose.Types.ObjectId.isValid(storyId)
    ) {
      return res.status(400).json({ message: 'A valid story ID is required.' });
    }

    const story = await Story.findOne({ _id: storyId, isDeleted: false });
    if (!story) return res.status(404).json({ message: 'Story not found.' });

    const sourceLanguage = canonicalLanguage(story.language);
    if (!sourceLanguage) {
      return res.status(422).json({
        message: 'This story language is not supported for translation yet.',
      });
    }

    if (story.storyText.length > MAX_STORY_CHARACTERS) {
      return res.status(413).json({
        message: 'This story is too long to translate right now.',
      });
    }

    if (normalizeLanguage(sourceLanguage) === normalizeLanguage(targetLanguage)) {
      return res.status(200).json(
        createTranslationResponse({
          storyId: story._id.toString(),
          sourceLanguage,
          targetLanguage,
          translatedText: story.storyText,
        })
      );
    }

    const translatedText = await translateStory({
      storyText: story.storyText,
      sourceLanguage,
      targetLanguage,
    });

    return res.status(200).json(
      createTranslationResponse({
        storyId: story._id.toString(),
        sourceLanguage,
        targetLanguage,
        translatedText,
      })
    );
  } catch (error) {
    if (error instanceof TranslationProviderError) {
      if (error.code === 'timeout') {
        return res.status(504).json({
          message: 'Translation is taking too long. Please try again.',
        });
      }
      return res.status(503).json({
        message: 'Translation is temporarily unavailable. Please try again later.',
      });
    }

    console.error('Story translation failed:', error?.name || 'UnknownError');
    return res.status(500).json({
      message: 'The story could not be translated right now.',
    });
  }
};

module.exports = { translateStoryController };
