const express = require('express');
const bcrypt = require('bcryptjs');
const User = require('../models/User');

const router = express.Router();
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

// @route   POST /api/auth/register
// @desc    Register a user
// @access  Public
router.post('/register', async (req, res) => {
  try {
    const { name, email, password } = req.body || {};

    if (typeof name !== 'string' || !name.trim()) {
      return res.status(400).json({ message: 'Name is required.' });
    }
    if (typeof email !== 'string' || !email.trim()) {
      return res.status(400).json({ message: 'Email is required.' });
    }
    const normalizedEmail = email.trim().toLowerCase();
    if (!emailPattern.test(normalizedEmail)) {
      return res.status(400).json({ message: 'Please provide a valid email address.' });
    }
    if (typeof password !== 'string' || !password.trim()) {
      return res.status(400).json({ message: 'Password is required.' });
    }
    if (password.length < 8 || password.length > 128) {
      return res.status(400).json({ message: 'Password must be between 8 and 128 characters.' });
    }

    const existingUser = await User.findOne({ email: normalizedEmail });
    if (existingUser) {
      return res.status(409).json({ message: 'An account with this email already exists.' });
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const user = await User.create({
      name: name.trim(),
      email: normalizedEmail,
      passwordHash,
    });

    return res.status(201).json({
      message: 'Registration successful.',
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        profileInfo: user.profileInfo,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      },
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({ message: 'An account with this email already exists.' });
    }
    if (error.name === 'ValidationError') {
      return res.status(400).json({ message: error.message });
    }
    console.error('Error registering user:', error);
    return res.status(500).json({ message: 'Registration failed due to a server error.' });
  }
});

module.exports = router;
