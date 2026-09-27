const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Please add a name'],
      trim: true,
      maxlength: [100, 'Name cannot be more than 100 characters'],
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
      avatar: {
        type: String,
        trim: true,
        maxlength: [2048, 'Avatar URL cannot be more than 2048 characters'],
      },
      interests: {
        type: [String],
        default: [],
      },
      location: {
        type: String,
        trim: true,
        maxlength: [100, 'Location cannot be more than 100 characters'],
      },
      ageGroup: {
        type: String,
        trim: true,
        maxlength: [30, 'Age or age group cannot be more than 30 characters'],
      },
      preferredLanguage: {
        type: String,
        enum: ['Tamil', 'Sinhala', 'English'],
      },
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('User', userSchema);
