const mongoose = require('mongoose');

const workspaceItemSchema = new mongoose.Schema({
  title: { type: String, trim: true, default: '' },
  content: { type: String, trim: true, default: '' },
  instructions: { type: String, trim: true, default: '' },
  culturalSignificance: { type: String, trim: true, default: '' },
  category: { type: String, trim: true, default: '' },
  imageDataUri: { type: String, default: '' },
  contentType: { type: String, enum: ['Story', 'Recipe', 'Tradition', 'Song', 'Festival', 'Other'], default: 'Story' },
  language: { type: String, trim: true, default: 'Tamil' },
  tags: { type: [String], default: [] },
  reviewNote: { type: String, trim: true, default: '' },
  submittedAt: { type: Date, default: null },
  reviewedAt: { type: Date, default: null },
  status: { type: String, enum: ['draft', 'under_review', 'changes_requested', 'approved', 'published'], default: 'draft' },
  storyId: { type: mongoose.Schema.ObjectId, ref: 'Story', default: null },
  updatedAt: { type: Date, default: Date.now },
}, { timestamps: true });

const connectionSchema = new mongoose.Schema(
  {
    requester: {
      type: mongoose.Schema.ObjectId,
      ref: 'User',
      required: true,
    },
    receiver: {
      type: mongoose.Schema.ObjectId,
      ref: 'User',
      required: true,
    },
    communityId: { type: String, trim: true, default: '' },
    communityName: { type: String, trim: true, default: '' },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'rejected', 'blocked'],
      default: 'pending',
    },
    messages: [{
      sender: { type: mongoose.Schema.ObjectId, ref: 'User', required: true },
      receiver: { type: mongoose.Schema.ObjectId, ref: 'User', required: true },
      text: { type: String, required: true, trim: true, maxlength: 4000 },
      createdAt: { type: Date, default: Date.now },
    }],
    chatConsentYouth: { type: Boolean, default: false },
    chatConsentElder: { type: Boolean, default: false },
    workspace: {
      title: { type: String, trim: true, default: '' },
      content: { type: String, trim: true, default: '' },
      instructions: { type: String, trim: true, default: '' },
      culturalSignificance: { type: String, trim: true, default: '' },
      category: { type: String, trim: true, default: '' },
      imageDataUri: { type: String, default: '' },
      contentType: { type: String, enum: ['Story', 'Recipe', 'Tradition', 'Song', 'Festival', 'Other'], default: 'Story' },
      language: { type: String, trim: true, default: 'Tamil' },
      tags: { type: [String], default: [] },
      reviewNote: { type: String, trim: true, default: '' },
      submittedAt: { type: Date, default: null },
      reviewedAt: { type: Date, default: null },
      status: { type: String, enum: ['draft', 'under_review', 'changes_requested', 'approved', 'published'], default: 'draft' },
      storyId: { type: mongoose.Schema.ObjectId, ref: 'Story', default: null },
      updatedAt: { type: Date, default: Date.now },
    },
    workspaceItems: { type: [workspaceItemSchema], default: [] },
  },
  {
    timestamps: true,
  }
);

// Prevent users from having multiple connections with each other in the same direction
connectionSchema.index({ requester: 1, receiver: 1 }, { unique: true });
connectionSchema.index({ receiver: 1, status: 1 });

module.exports = mongoose.model('Connection', connectionSchema);
