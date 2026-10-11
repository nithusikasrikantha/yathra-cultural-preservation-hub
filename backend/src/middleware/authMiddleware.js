const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { jwtSecret } = require('../config/env');

const requireAuth = async (req, res, next) => {
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

const requireYouth = (req, res, next) => {
  if (req.user.role !== 'youth') {
    return res.status(403).json({ message: 'A youth account is required.' });
  }
  return next();
};

module.exports = { requireAuth, requireYouth };
