const mongoose = require('mongoose');

const storySchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Story title is required'],
      trim: true,
    },
    category: {
      type: String,
      required: [true, 'Category is required'],
      trim: true,
    },
    language: {
      type: String,
      required: [true, 'Language is required'],
      trim: true,
    },
    storyText: {
      type: String,
      required: [true, 'Story text is required'],
      trim: true,
    },
    audioPath: {
      type: String,
      default: null,
    },
    imageDataUri: { type: String, default: '' },
    bannerImage: { type: String, default: null },
    additionalImages: { type: [String], default: [] },
    location: { type: String, default: '' },
    timePeriod: { type: String, default: '' },
    community: { type: String, default: '' },
    tags: {
      type: [String],
      default: [],
    },
    connection: { type: mongoose.Schema.ObjectId, ref: 'Connection', default: null },
    communityId: { type: String, default: '' },
    communityName: { type: String, default: '' },
    contributors: [{ type: mongoose.Schema.ObjectId, ref: 'User' }],
    publishedBy: { type: mongoose.Schema.ObjectId, ref: 'User', default: null },
    isDeleted: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Story', storySchema);
