const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();
const Story = require('../models/Story');
const authenticate = require('../middleware/authenticate');

const requireElder = (req, res, next) => {
  if (req.user?.role !== 'elder') return res.status(403).json({ message: 'Only an elder account can publish or manage stories.' });
  next();
};

// Helper to validate MongoDB ObjectId
const isValidObjectId = (id) => mongoose.Types.ObjectId.isValid(id);

const escapeRegex = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const normalizeTags = (tags) => {
  if (tags === undefined) {
    return { value: undefined };
  }

  if (!Array.isArray(tags)) {
    return { error: 'Tags must be an array.' };
  }

  const normalizedTags = [];
  const seenTags = new Set();

  for (const tag of tags) {
    if (typeof tag !== 'string' || !tag.trim()) {
      return { error: 'Every tag must be a non-empty string.' };
    }

    const trimmedTag = tag.trim();
    const normalizedKey = trimmedTag.toLowerCase();
    if (!seenTags.has(normalizedKey)) {
      seenTags.add(normalizedKey);
      normalizedTags.push(trimmedTag);
    }
  }

  return { value: normalizedTags };
};


const imageFields = (body) => {
  const valid = value => typeof value === 'string' && (/^\/uploads\/[a-f0-9-]+\.(jpg|png|webp)$/.test(value) || /^https?:\/\//.test(value));
  if (body.bannerImage !== undefined && body.bannerImage !== null && !valid(body.bannerImage)) return { error: 'Invalid banner image.' };
  if (body.additionalImages !== undefined && (!Array.isArray(body.additionalImages) || body.additionalImages.length > 8 || !body.additionalImages.every(valid))) return { error: 'Choose up to eight valid additional images.' };
  const value = {};
  for (const key of ['bannerImage', 'additionalImages', 'location', 'timePeriod', 'community']) {
    if (body[key] !== undefined) value[key] = body[key];
  }
  for (const key of ['location', 'timePeriod', 'community']) {
    if (value[key] !== undefined && typeof value[key] !== 'string') return { error: `Invalid ${key}.` };
  }
  return { value };
};

// @route   POST /api/stories
// @desc    Publish a new cultural story
// @access  Elder
router.post('/', authenticate, requireElder, async (req, res) => {
  try {
    const images = imageFields(req.body);
    if (images.error) return res.status(400).json({ message: images.error });
    const { title, category, language, storyText, audioPath, tags } = req.body;

    // Field validation
    if (!title || !title.trim()) {
      return res.status(400).json({ message: 'Title is required.' });
    }
    if (!category || !category.trim()) {
      return res.status(400).json({ message: 'Category is required.' });
    }
    if (!language || !language.trim()) {
      return res.status(400).json({ message: 'Language is required.' });
    }
    if (!storyText || !storyText.trim()) {
      return res.status(400).json({ message: 'Story text is required.' });
    }

    const normalizedTags = normalizeTags(tags);
    if (normalizedTags.error) {
      return res.status(400).json({ message: normalizedTags.error });
    }

    const newStory = new Story({
      title: title.trim(),
      category: category.trim(),
      language: language.trim(),
      storyText: storyText.trim(),
      audioPath: audioPath || null,
      tags: normalizedTags.value,
      publishedBy: req.user._id,
      contributors: [req.user._id],
      isDeleted: false,
      ...images.value,
    });

    const savedStory = await newStory.save();

    return res.status(201).json({
      message: 'Story published successfully',
      story: savedStory,
    });
  } catch (error) {
    console.error('Error publishing story:', error);
    return res.status(500).json({
      message: 'Failed to publish story due to a server error.',
      error: error.message,
    });
  }
});

// @route   GET /api/stories
// @desc    Get paginated active (non-deleted) stories
// @access  Public
router.get('/', async (req, res) => {
  try {
    const parsePositiveInteger = (value, defaultValue) => {
      if (value === undefined) return defaultValue;
      if (typeof value !== 'string' || !/^\d+$/.test(value)) return null;

      const parsedValue = Number(value);
      return Number.isSafeInteger(parsedValue) && parsedValue > 0 ? parsedValue : null;
    };

    const page = parsePositiveInteger(req.query.page, 1);
    const limit = parsePositiveInteger(req.query.limit, 10);

    if (page === null || limit === null || limit > 50) {
      return res.status(400).json({
        message: 'Page and limit must be positive integers, and limit cannot exceed 50.',
      });
    }

    const skip = (page - 1) * limit;
    if (!Number.isSafeInteger(skip)) {
      return res.status(400).json({ message: 'Page value is too large.' });
    }

    const filter = { isDeleted: false };
    const { search, category, tags } = req.query;

    if (search !== undefined) {
      if (typeof search !== 'string' || !search.trim()) {
        return res.status(400).json({ message: 'Search must be a non-empty string.' });
      }

      const searchRegex = new RegExp(escapeRegex(search.trim()), 'i');
      filter.$or = [{ title: searchRegex }, { storyText: searchRegex }];
    }

    if (category !== undefined) {
      if (typeof category !== 'string' || !category.trim()) {
        return res.status(400).json({ message: 'Category must be a non-empty string.' });
      }

      filter.category = new RegExp(`^${escapeRegex(category.trim())}$`, 'i');
    }

    if (tags !== undefined) {
      if (typeof tags !== 'string' || !tags.trim()) {
        return res.status(400).json({ message: 'Tags must be a comma-separated string.' });
      }

      const normalizedTags = normalizeTags(tags.split(','));
      if (normalizedTags.error) {
        return res.status(400).json({ message: normalizedTags.error });
      }

      filter.tags = {
        $all: normalizedTags.value.map(
          (tag) => new RegExp(`^${escapeRegex(tag)}$`, 'i')
        ),
      };
    }

    const [items, totalItems] = await Promise.all([
      Story.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
      Story.countDocuments(filter),
    ]);

    return res.status(200).json({
      items,
      pagination: {
        currentPage: page,
        pageSize: limit,
        totalItems,
        totalPages: Math.ceil(totalItems / limit),
      },
    });
  } catch (error) {
    console.error('Error fetching stories:', error);
    return res.status(500).json({
      message: 'Failed to fetch stories.',
      error: error.message,
    });
  }
});

// @route   GET /api/stories/:id
// @desc    Get single story by ID
// @access  Public
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid story ID format.' });
    }

    const story = await Story.findOne({ _id: id, isDeleted: false });
    if (!story) {
      return res.status(404).json({ message: 'Story not found.' });
    }

    return res.status(200).json({ story });
  } catch (error) {
    console.error('Error fetching story:', error);
    return res.status(500).json({
      message: 'Failed to fetch story details.',
      error: error.message,
    });
  }
});

// @route   PUT /api/stories/:id
// @desc    Edit/Update an existing story
// @access  Elder
router.put('/:id', authenticate, requireElder, async (req, res) => {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid story ID format.' });
    }

    const story = await Story.findOne({ _id: id, isDeleted: false });
    if (!story) {
      return res.status(404).json({ message: 'Story not found or has been deleted.' });
    }

    const images = imageFields(req.body);
    if (images.error) return res.status(400).json({ message: images.error });
    const { title, category, language, storyText, audioPath, tags } = req.body;

    // Field validation
    if (title !== undefined) {
      if (!title || !title.trim()) {
        return res.status(400).json({ message: 'Title cannot be empty.' });
      }
      story.title = title.trim();
    }

    if (category !== undefined) {
      if (!category || !category.trim()) {
        return res.status(400).json({ message: 'Category cannot be empty.' });
      }
      story.category = category.trim();
    }

    if (language !== undefined) {
      if (!language || !language.trim()) {
        return res.status(400).json({ message: 'Language cannot be empty.' });
      }
      story.language = language.trim();
    }

    if (storyText !== undefined) {
      if (!storyText || !storyText.trim()) {
        return res.status(400).json({ message: 'Story text cannot be empty.' });
      }
      story.storyText = storyText.trim();
    }

    if (audioPath !== undefined) {
      story.audioPath = audioPath;
    }

    if (tags !== undefined) {
      const normalizedTags = normalizeTags(tags);
      if (normalizedTags.error) {
        return res.status(400).json({ message: normalizedTags.error });
      }
      story.tags = normalizedTags.value;
    }

    Object.assign(story, images.value);
    const updatedStory = await story.save();

    return res.status(200).json({
      message: 'Story updated successfully',
      story: updatedStory,
    });
  } catch (error) {
    console.error('Error updating story:', error);
    return res.status(500).json({
      message: 'Failed to update story due to a server error.',
      error: error.message,
    });
  }
});

// @route   DELETE /api/stories/:id
// @desc    Soft delete a story (sets isDeleted = true)
// @access  Elder
router.delete('/:id', authenticate, requireElder, async (req, res) => {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid story ID format.' });
    }

    const story = await Story.findOne({ _id: id, isDeleted: false });
    if (!story) {
      return res.status(404).json({ message: 'Story not found or already deleted.' });
    }

    story.isDeleted = true;
    await story.save();

    return res.status(200).json({
      message: 'Story soft deleted successfully',
      id: story._id,
    });
  } catch (error) {
    console.error('Error deleting story:', error);
    return res.status(500).json({
      message: 'Failed to delete story due to a server error.',
      error: error.message,
    });
  }
});

module.exports = router;
