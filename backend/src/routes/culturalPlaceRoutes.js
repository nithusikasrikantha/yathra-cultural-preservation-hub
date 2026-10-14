const express = require('express');
const mongoose = require('mongoose');
const CulturalPlace = require('../models/CulturalPlace');

const router = express.Router();

const escapeRegex = value => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const parsePositiveInteger = (value, fallback) => {
  if (value === undefined) return fallback;
  if (typeof value !== 'string' || !/^\d+$/.test(value)) return null;
  const parsed = Number(value);
  return Number.isSafeInteger(parsed) && parsed > 0 ? parsed : null;
};

const addExactFilter = (filter, field, value) => {
  if (value === undefined) return null;
  if (typeof value !== 'string' || !value.trim()) return `${field} must be a non-empty string.`;
  filter[field] = new RegExp(`^${escapeRegex(value.trim())}$`, 'i');
  return null;
};

router.get('/', async (req, res) => {
  try {
    const page = parsePositiveInteger(req.query.page, 1);
    const limit = parsePositiveInteger(req.query.limit, 50);
    if (page === null || limit === null || limit > 100) {
      return res.status(400).json({ message: 'Page and limit must be positive integers, and limit cannot exceed 100.' });
    }

    const filter = {};
    for (const field of ['category', 'province', 'district', 'language', 'region']) {
      const targetField = field === 'category'
        ? 'categories'
        : field === 'language'
          ? 'languages'
          : field;
      const error = addExactFilter(filter, targetField, req.query[field]);
      if (error) return res.status(400).json({ message: error });
    }

    const search = req.query.q ?? req.query.search;
    if (search !== undefined) {
      if (typeof search !== 'string' || !search.trim()) {
        return res.status(400).json({ message: 'Search must be a non-empty string.' });
      }
      const expression = new RegExp(escapeRegex(search.trim()), 'i');
      filter.$or = [
        { name: expression },
        { description: expression },
        { province: expression },
        { district: expression },
        { region: expression },
        { categories: expression },
        { tags: expression },
        { languages: expression },
        { traditions: expression },
      ];
    }

    if (req.query.hasStories !== undefined) {
      if (req.query.hasStories !== 'true' && req.query.hasStories !== 'false') {
        return res.status(400).json({ message: 'hasStories must be true or false.' });
      }
      if (req.query.hasStories === 'true') filter['relatedStoryIds.0'] = { $exists: true };
      else filter['relatedStoryIds.0'] = { $exists: false };
    }

    const skip = (page - 1) * limit;
    if (!Number.isSafeInteger(skip)) return res.status(400).json({ message: 'Page value is too large.' });

    const [items, totalItems] = await Promise.all([
      CulturalPlace.find(filter).sort({ name: 1 }).skip(skip).limit(limit).lean(),
      CulturalPlace.countDocuments(filter),
    ]);

    return res.status(200).json({
      items,
      pagination: {
        currentPage: page,
        pageSize: limit,
        totalItems,
        totalPages: Math.ceil(totalItems / limit),
      },
    });
  } catch (error) {
    console.error('Error fetching cultural places:', error);
    return res.status(500).json({ message: 'Failed to fetch cultural places.' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid cultural place ID format.' });
    }
    const place = await CulturalPlace.findById(req.params.id).lean();
    if (!place) return res.status(404).json({ message: 'Cultural place not found.' });
    return res.status(200).json({ place });
  } catch (error) {
    console.error('Error fetching cultural place:', error);
    return res.status(500).json({ message: 'Failed to fetch cultural place.' });
  }
});

module.exports = router;
