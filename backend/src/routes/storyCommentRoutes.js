const router = require('express').Router();
const mongoose = require('mongoose');
const authenticate = require('../middleware/authenticate');
const Story = require('../models/Story');
const Comment = require('../models/StoryComment');
router.use('/:id/comments', async (req, res, next) => {
  if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ message: 'Invalid story.' });
  try {
    if (!await Story.exists({ _id: req.params.id, isDeleted: false })) return res.status(404).json({ message: 'Story not found.' });
    next();
  } catch (_) { res.status(500).json({ message: 'Comments could not be loaded.' }); }
});
router.get('/:id/comments', async (req, res) => {
  try {
    const comments = await Comment.find({ story: req.params.id }).sort({ createdAt: -1 }).limit(100).lean();
    res.json({ comments });
  } catch (_) { res.status(500).json({ message: 'Comments could not be loaded.' }); }
});
router.post('/:id/comments', authenticate, async (req, res) => {
  const text = req.body?.text;
  if (typeof text !== 'string' || !text.trim() || text.trim().length > 2000) return res.status(400).json({ message: 'Write a comment of up to 2,000 characters.' });
  try {
    const comment = await Comment.create({ story: req.params.id, author: req.user._id, authorName: req.user.name, text: text.trim() });
    res.status(201).json({ comment });
  } catch (_) { res.status(500).json({ message: 'Comment could not be saved.' }); }
});
module.exports = router;
