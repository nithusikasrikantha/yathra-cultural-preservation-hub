const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { jwtSecret } = require('../config/env');
const { requireAuth, requireYouth } = require('../middleware/authMiddleware');

const router = express.Router();
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const youthLanguages = new Set(['Tamil', 'Sinhala', 'English']);
const youthInterests = new Set([
  'Folklore',
  'Traditional Food',
  'Music',
  'Dance',
  'Festivals',
  'Language',
  'History',
  'Crafts',
]);
const youthProfileFields = new Set([
  'name',
  'ageGroup',
  'preferredLanguage',
  'location',
  'interests',
  'avatar',
]);

const isNonEmptyString = (value) => typeof value === 'string' && value.trim().length > 0;

const isYouthProfileComplete = (user) => {
  const profile = user.profileInfo || {};
  return user.role === 'youth'
    && isNonEmptyString(user.name)
    && isNonEmptyString(profile.ageGroup)
    && youthLanguages.has(profile.preferredLanguage)
    && isNonEmptyString(profile.location)
    && Array.isArray(profile.interests)
    && profile.interests.length > 0;
};

const youthProfileResponse = (user) => ({
  name: user.name,
  ageGroup: user.profileInfo?.ageGroup || '',
  preferredLanguage: user.profileInfo?.preferredLanguage || '',
  location: user.profileInfo?.location || '',
  interests: user.profileInfo?.interests || [],
  avatar: user.profileInfo?.avatar || null,
  profileComplete: isYouthProfileComplete(user),
});

const publicUser = (user) => ({
  _id: user._id,
  name: user.name,
  email: user.email,
  role: user.role,
  profileInfo: user.profileInfo,
  profileComplete: isYouthProfileComplete(user),
  createdAt: user.createdAt,
  updatedAt: user.updatedAt,
});

const createToken = (user) => jwt.sign(
  { sub: user._id.toString(), role: user.role },
  jwtSecret,
  { expiresIn: '1h', issuer: 'yathra-api', audience: 'yathra-app' }
);

const validateYouthProfile = (body) => {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return { error: 'A youth profile object is required.' };
  }

  const unsupportedFields = Object.keys(body).filter((field) => !youthProfileFields.has(field));
  if (unsupportedFields.length > 0) {
    return { error: `Unsupported youth profile field: ${unsupportedFields[0]}.` };
  }

  const { name, ageGroup, preferredLanguage, location, interests, avatar } = body;

  if (!isNonEmptyString(name) || name.trim().length > 100) {
    return { error: 'Name is required and cannot exceed 100 characters.' };
  }
  if (!isNonEmptyString(ageGroup) || ageGroup.trim().length > 30) {
    return { error: 'Age or age group is required and cannot exceed 30 characters.' };
  }
  if (!youthLanguages.has(preferredLanguage)) {
    return { error: 'Preferred language must be Tamil, Sinhala, or English.' };
  }
  if (!isNonEmptyString(location) || location.trim().length > 100) {
    return { error: 'Location is required and cannot exceed 100 characters.' };
  }
  if (!Array.isArray(interests) || interests.length === 0) {
    return { error: 'Select at least one cultural interest.' };
  }

  const normalizedInterests = [];
  const seenInterests = new Set();
  for (const interest of interests) {
    if (!youthInterests.has(interest)) {
      return { error: 'One or more cultural interests are invalid.' };
    }
    if (!seenInterests.has(interest)) {
      seenInterests.add(interest);
      normalizedInterests.push(interest);
    }
  }

  let normalizedAvatar;
  if (avatar !== undefined && avatar !== null && avatar !== '') {
    if (typeof avatar !== 'string' || avatar.length > 2048) {
      return { error: 'Avatar must be a valid URL no longer than 2048 characters.' };
    }
    try {
      const avatarUrl = new URL(avatar);
      if (!['http:', 'https:'].includes(avatarUrl.protocol)) throw new Error('Invalid protocol');
      normalizedAvatar = avatar.trim();
    } catch (_) {
      return { error: 'Avatar must be a valid HTTP or HTTPS URL.' };
    }
  }

  return {
    value: {
      name: name.trim(),
      ageGroup: ageGroup.trim(),
      preferredLanguage,
      location: location.trim(),
      interests: normalizedInterests,
      avatar: normalizedAvatar,
    },
  };
};

// @route   POST /api/auth/register
// @desc    Register a user
// @access  Public
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, role } = req.body || {};

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
    if (!['elder', 'youth'].includes(role)) {
      return res.status(400).json({ message: 'Please select Elder or Youth.' });
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
      role,
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
router.put('/role', requireAuth, async (req, res) => {
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

// @route   GET /api/auth/youth-profile
// @desc    Get the authenticated youth user's profile
// @access  Authenticated youth user
router.get('/youth-profile', requireAuth, requireYouth, (req, res) => {
  return res.status(200).json({ profile: youthProfileResponse(req.user) });
});

// @route   PUT /api/auth/youth-profile
// @desc    Create or replace the authenticated youth user's profile fields
// @access  Authenticated youth user
router.put('/youth-profile', requireAuth, requireYouth, async (req, res) => {
  const validated = validateYouthProfile(req.body);
  if (validated.error) {
    return res.status(400).json({ message: validated.error });
  }

  try {
    const profile = validated.value;
    req.user.name = profile.name;
    req.user.profileInfo = {
      bio: req.user.profileInfo?.bio,
      ageGroup: profile.ageGroup,
      preferredLanguage: profile.preferredLanguage,
      location: profile.location,
      interests: profile.interests,
      avatar: profile.avatar,
    };
    await req.user.save();

    return res.status(200).json({
      message: 'Youth profile saved successfully.',
      profile: youthProfileResponse(req.user),
    });
  } catch (error) {
    if (error.name === 'ValidationError') {
      return res.status(400).json({ message: error.message });
    }
    console.error('Error saving youth profile:', error);
    return res.status(500).json({ message: 'Youth profile could not be saved.' });
  }
});

module.exports = router;
