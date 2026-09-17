const express = require('express');
const router = express.Router();
const Story = require('../models/Story');

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
// @desc    Get all stories (useful for testing/verification)
// @access  Public
router.get('/', async (req, res) => {
  try {
    const stories = await Story.find().sort({ createdAt: -1 });
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

module.exports = router;
