const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Please add a name'],
      trim: true,
    },
    email: {
      type: String,
      required: [true, 'Please add an email'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/, 'Please add a valid email'],
    },
    passwordHash: {
      type: String,
      required: [true, 'Please add a password'],
      minlength: 8,
      select: false, // Don't return password by default
    },
    role: {
      type: String,
      enum: ['elder', 'youth', 'admin'],
      default: 'youth',
    },
    profileInfo: {
      bio: String,
      avatar: String,
      interests: [String],
      location: String,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('User', userSchema);
