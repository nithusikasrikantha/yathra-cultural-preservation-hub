const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { jwtSecret } = require('../config/env');

const router = express.Router();
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

const publicUser = (user) => ({
  _id: user._id,
  name: user.name,
  email: user.email,
  role: user.role,
  profileInfo: user.profileInfo,
  createdAt: user.createdAt,
  updatedAt: user.updatedAt,
});

const createToken = (user) => jwt.sign(
  { sub: user._id.toString(), role: user.role },
  jwtSecret,
  { expiresIn: '1h', issuer: 'yathra-api', audience: 'yathra-app' }
);

const authenticate = async (req, res, next) => {
  const authHeader = req.get('authorization') || '';
  const [scheme, token] = authHeader.split(' ');
  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ message: 'Authentication required.' });
  }
  try {
    const payload = jwt.verify(token, jwtSecret);
    const user = await User.findById(payload.sub);
    if (!user) return res.status(401).json({ message: 'Authentication required.' });
    req.user = user;
    return next();
  } catch (_) {
    return res.status(401).json({ message: 'Authentication required.' });
  }
};

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

// @route   POST /api/auth/login
// @access  Public
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};
    if (typeof email !== 'string' || !email.trim()) {
      return res.status(400).json({ message: 'Email is required.' });
    }
    if (typeof password !== 'string' || !password) {
      return res.status(400).json({ message: 'Password is required.' });
    }
    const normalizedEmail = email.trim().toLowerCase();
    if (!emailPattern.test(normalizedEmail)) {
      return res.status(400).json({ message: 'Please provide a valid email address.' });
    }
    const user = await User.findOne({ email: normalizedEmail }).select('+passwordHash');
    const validPassword = user && await bcrypt.compare(password, user.passwordHash);
    if (!validPassword) {
      return res.status(401).json({ message: 'Invalid email or password.' });
    }
    const token = createToken(user);
    return res.status(200).json({ message: 'Login successful.', token, user: publicUser(user) });
  } catch (error) {
    console.error('Error logging in user:', error);
    return res.status(500).json({ message: 'Login failed due to a server error.' });
  }
});

// @route   PUT /api/auth/role
// @access  Authenticated user
router.put('/role', authenticate, async (req, res) => {
  const { role } = req.body || {};
  if (!['elder', 'youth'].includes(role)) {
    return res.status(400).json({ message: 'Role must be elder or youth.' });
  }
  try {
    req.user.role = role;
    await req.user.save();
    return res.status(200).json({
      message: 'Role updated successfully.',
      token: createToken(req.user),
      user: publicUser(req.user),
    });
  } catch (error) {
    console.error('Error updating user role:', error);
    return res.status(500).json({ message: 'Role update failed due to a server error.' });
  }
});

module.exports = router;
