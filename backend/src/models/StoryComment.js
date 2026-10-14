const mongoose = require('mongoose');
module.exports = mongoose.model('StoryComment', new mongoose.Schema({
  story: { type: mongoose.Schema.Types.ObjectId, ref: 'Story', required: true, index: true },
  author: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  authorName: { type: String, required: true },
  text: { type: String, required: true, maxlength: 2000, trim: true },
}, { timestamps: true }));
