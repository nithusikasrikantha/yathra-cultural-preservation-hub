const { getDatabase } = require('../config/db');
const {
  CULTURAL_CONTENT_COLLECTION,
  culturalContentProjection,
} = require('../models/culturalContentModel');

const DEFAULT_PAGE = 1;
const DEFAULT_LIMIT = 10;
const MAX_LIMIT = 50;

function parsePositiveInteger(value, fallback) {
  if (value === undefined) {
    return fallback;
  }

  if (!/^\d+$/.test(String(value))) {
    return null;
  }

  const parsedValue = Number(value);
  return parsedValue > 0 ? parsedValue : null;
}

async function getCulturalContent(req, res) {
  const page = parsePositiveInteger(req.query.page, DEFAULT_PAGE);
  const limit = parsePositiveInteger(req.query.limit, DEFAULT_LIMIT);

  if (!page || !limit) {
    return res.status(400).json({
      error: 'Invalid pagination parameters',
      message: 'page and limit must be positive integers.',
    });
  }

  const pageSize = Math.min(limit, MAX_LIMIT);
  const skip = (page - 1) * pageSize;

  try {
    const db = getDatabase();
    const collection = db.collection(CULTURAL_CONTENT_COLLECTION);

    const [items, totalItems] = await Promise.all([
      collection
        .find({}, { projection: culturalContentProjection })
        .sort({ createdAt: -1, _id: -1 })
        .skip(skip)
        .limit(pageSize)
        .toArray(),
      collection.countDocuments({}),
    ]);

    return res.status(200).json({
      items,
      pagination: {
        currentPage: page,
        pageSize,
        totalItems,
        totalPages: totalItems === 0 ? 0 : Math.ceil(totalItems / pageSize),
      },
    });
  } catch (error) {
    console.error('Failed to retrieve cultural content:', error.message);

    return res.status(500).json({
      error: 'Unable to retrieve cultural content',
      message: 'An unexpected server error occurred.',
    });
  }
}

module.exports = {
  getCulturalContent,
};
