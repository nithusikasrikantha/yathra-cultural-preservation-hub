const mongoose = require('mongoose');

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
    status: {
      type: String,
      enum: ['pending', 'accepted', 'rejected', 'blocked'],
      default: 'pending',
    },
  },
  {
    timestamps: true,
  }
);

// Prevent users from having multiple connections with each other in the same direction
connectionSchema.index({ requester: 1, receiver: 1 }, { unique: true });

module.exports = mongoose.model('Connection', connectionSchema);
