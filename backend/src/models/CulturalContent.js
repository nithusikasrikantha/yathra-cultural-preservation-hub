const mongoose = require('mongoose');

const culturalContentSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Please add a title'],
      trim: true,
      maxlength: [100, 'Title cannot be more than 100 characters'],
    },
    content: {
      type: String,
      required: [true, 'Please add content'],
    },
    category: {
      type: String,
      required: [true, 'Please add a category'],
      enum: ['story', 'tradition', 'recipe', 'history', 'other'],
    },
    tags: [String],
    author: {
      type: mongoose.Schema.ObjectId,
      ref: 'User',
      required: true,
    },
    language: {
      type: String,
      default: 'English',
    },
    media: [
      {
        type: {
          type: String,
          enum: ['image', 'video', 'audio'],
        },
        url: String,
      },
    ],
    status: {
      type: String,
      enum: ['draft', 'published', 'archived'],
      default: 'published',
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('CulturalContent', culturalContentSchema);
