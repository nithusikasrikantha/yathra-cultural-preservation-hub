const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();
const Story = require('../models/Story');

// Helper to validate MongoDB ObjectId
const isValidObjectId = (id) => mongoose.Types.ObjectId.isValid(id);

// @route   POST /api/stories
// @desc    Publish a new cultural story
// @access  Public
router.post('/', async (req, res) => {
  try {
    const { title, category, language, storyText, audioPath } = req.body;

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

    const newStory = new Story({
      title: title.trim(),
      category: category.trim(),
      language: language.trim(),
      storyText: storyText.trim(),
      audioPath: audioPath || null,
      isDeleted: false,
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
// @desc    Get all active (non-deleted) stories
// @access  Public
router.get('/', async (req, res) => {
  try {
    const stories = await Story.find({ isDeleted: false }).sort({ createdAt: -1 });
    return res.status(200).json({
      count: stories.length,
      stories,
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
// @access  Public
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid story ID format.' });
    }

    const story = await Story.findOne({ _id: id, isDeleted: false });
    if (!story) {
      return res.status(404).json({ message: 'Story not found or has been deleted.' });
    }

    const { title, category, language, storyText, audioPath } = req.body;

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
// @access  Public
router.delete('/:id', async (req, res) => {
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
