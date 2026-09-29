const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { jwtSecret } = require('../config/env');

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

const isYouthProfileComplete = (user) => {
  const profile = user.profileInfo || {};

  return user.role === 'youth'
    && typeof user.name === 'string'
    && user.name.trim().length > 0
    && typeof profile.ageGroup === 'string'
    && profile.ageGroup.trim().length > 0
    && youthLanguages.has(profile.preferredLanguage)
    && typeof profile.location === 'string'
    && profile.location.trim().length > 0
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

const authenticate = async (req, res, next) => {
  const authHeader = req.get('authorization') || '';
  const [scheme, token] = authHeader.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({
      message: 'Authentication required.',
    });
  }

  try {
    const payload = jwt.verify(token, jwtSecret);
    const user = await User.findById(payload.sub);

    if (!user) {
      return res.status(401).json({
        message: 'Authentication required.',
      });
    }

    req.user = user;
    return next();
  } catch (_) {
    return res.status(401).json({
      message: 'Authentication required.',
    });
  }
};

const requireYouth = (req, res, next) => {
  if (req.user.role !== 'youth') {
    return res.status(403).json({
      message: 'A youth account is required.',
    });
  }

  return next();
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
      return res.status(400).json({
        message: 'Please provide a valid email address.',
      });
    }

    if (typeof password !== 'string' || !password.trim()) {
      return res.status(400).json({
        message: 'Password is required.',
      });
    }

    if (password.length < 8 || password.length > 128) {
      return res.status(400).json({
        message: 'Password must be between 8 and 128 characters.',
      });
    }

    if (!['elder', 'youth'].includes(role)) {
      return res.status(400).json({
        message: 'Please select Elder or Youth.',
      });
    }

    const existingUser = await User.findOne({
      email: normalizedEmail,
    });

    if (existingUser) {
      return res.status(409).json({
        message: 'An account with this email already exists.',
      });
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
      return res.status(409).json({
        message: 'An account with this email already exists.',
      });
    }

    if (error.name === 'ValidationError') {
      return res.status(400).json({
        message: error.message,
      });
    }

    console.error('Error registering user:', error);

    return res.status(500).json({
      message: 'Registration failed due to a server error.',
    });
  }
});

// @route   POST /api/auth/login
// @desc    Login a user
// @access  Public
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};

    if (typeof email !== 'string' || !email.trim()) {
      return res.status(400).json({
        message: 'Email is required.',
      });
    }

    if (typeof password !== 'string' || !password) {
      return res.status(400).json({
        message: 'Password is required.',
      });
    }

    const normalizedEmail = email.trim().toLowerCase();

    if (!emailPattern.test(normalizedEmail)) {
      return res.status(400).json({
        message: 'Please provide a valid email address.',
      });
    }

    const user = await User.findOne({
      email: normalizedEmail,
    }).select('+passwordHash');

    const validPassword =
      user && await bcrypt.compare(password, user.passwordHash);

    if (!validPassword) {
      return res.status(401).json({
        message: 'Invalid email or password.',
      });
    }

    const token = createToken(user);

    return res.status(200).json({
      message: 'Login successful.',
      token,
      user: publicUser(user),
    });
  } catch (error) {
    console.error('Error logging in user:', error);

    return res.status(500).json({
      message: 'Login failed due to a server error.',
    });
  }
});

// @route   PUT /api/auth/role
// @access  Authenticated user
router.put('/role', authenticate, async (req, res) => {
  const { role } = req.body || {};

  if (!['elder', 'youth'].includes(role)) {
    return res.status(400).json({
      message: 'Role must be elder or youth.',
    });
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

    return res.status(500).json({
      message: 'Role update failed due to a server error.',
    });
  }
});

// @route   GET /api/auth/youth-profile
// @desc    Get the authenticated youth user's profile
// @access  Authenticated youth user
router.get('/youth-profile', authenticate, requireYouth, (req, res) => {
  return res.status(200).json({
    profile: youthProfileResponse(req.user),
  });
});

// @route   PUT /api/auth/youth-profile
// @desc    Create or update the authenticated youth user's profile
// @access  Authenticated youth user
router.put('/youth-profile', authenticate, requireYouth, async (req, res) => {
  const {
    name,
    ageGroup,
    preferredLanguage,
    location,
    interests,
    avatar,
  } = req.body || {};

  if (typeof name !== 'string' || !name.trim()) {
    return res.status(400).json({
      message: 'Name is required.',
    });
  }

  if (typeof ageGroup !== 'string' || !ageGroup.trim()) {
    return res.status(400).json({
      message: 'Age or age group is required.',
    });
  }

  if (!youthLanguages.has(preferredLanguage)) {
    return res.status(400).json({
      message: 'Preferred language must be Tamil, Sinhala, or English.',
    });
  }

  if (typeof location !== 'string' || !location.trim()) {
    return res.status(400).json({
      message: 'Location is required.',
    });
  }

  if (!Array.isArray(interests) || interests.length === 0) {
    return res.status(400).json({
      message: 'Select at least one cultural interest.',
    });
  }

  const invalidInterest = interests.find(
    (interest) => !youthInterests.has(interest),
  );

  if (invalidInterest) {
    return res.status(400).json({
      message: 'One or more cultural interests are invalid.',
    });
  }

  if (
    avatar !== undefined &&
    avatar !== null &&
    avatar !== '' &&
    (typeof avatar !== 'string' || avatar.length > 2048)
  ) {
    return res.status(400).json({
      message: 'Avatar must be a valid URL no longer than 2048 characters.',
    });
  }

  try {
    req.user.name = name.trim();

    req.user.profileInfo = {
      bio: req.user.profileInfo?.bio,
      ageGroup: ageGroup.trim(),
      preferredLanguage,
      location: location.trim(),
      interests: [...new Set(interests)],
      avatar: avatar || null,
    };

    await req.user.save();

    return res.status(200).json({
      message: 'Youth profile saved successfully.',
      profile: youthProfileResponse(req.user),
    });
  } catch (error) {
    if (error.name === 'ValidationError') {
      return res.status(400).json({
        message: error.message,
      });
    }

    console.error('Error saving youth profile:', error);

    return res.status(500).json({
      message: 'Youth profile could not be saved.',
    });
  }
});

module.exports = router;