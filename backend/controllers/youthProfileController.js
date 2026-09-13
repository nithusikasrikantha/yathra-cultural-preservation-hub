const { ObjectId } = require('mongodb');

const { getDatabase } = require('../config/db');
const {
  YOUTH_PROFILE_COLLECTION,
  allowedPreferredLanguages,
  youthProfileProjection,
} = require('../models/youthProfileModel');

const supportedFields = [
  'name',
  'age',
  'ageGroup',
  'preferredLanguage',
  'location',
  'interests',
];

function isValidObjectId(id) {
  return ObjectId.isValid(id) && String(new ObjectId(id)) === id;
}

function trimString(value) {
  return typeof value === 'string' ? value.trim() : value;
}

function buildProfilePayload(body, { isCreate }) {
  const payload = {};
  const errors = [];

  for (const field of supportedFields) {
    if (Object.prototype.hasOwnProperty.call(body, field)) {
      payload[field] = body[field];
    }
  }

  if (Object.prototype.hasOwnProperty.call(payload, 'name')) {
    payload.name = trimString(payload.name);
  }

  if (Object.prototype.hasOwnProperty.call(payload, 'ageGroup')) {
    payload.ageGroup = trimString(payload.ageGroup);
  }

  if (Object.prototype.hasOwnProperty.call(payload, 'preferredLanguage')) {
    payload.preferredLanguage = trimString(payload.preferredLanguage);
  }

  if (Object.prototype.hasOwnProperty.call(payload, 'location')) {
    payload.location = trimString(payload.location);
  }

  if (isCreate && (!payload.name || typeof payload.name !== 'string')) {
    errors.push('name is required and must not be empty.');
  }

  if (
    Object.prototype.hasOwnProperty.call(payload, 'name') &&
    (!payload.name || typeof payload.name !== 'string')
  ) {
    errors.push('name must not be empty.');
  }

  if (Object.prototype.hasOwnProperty.call(payload, 'age')) {
    const age = Number(payload.age);

    if (!Number.isFinite(age) || age <= 0) {
      errors.push('age must be a positive number.');
    } else {
      payload.age = age;
    }
  }

  if (
    Object.prototype.hasOwnProperty.call(payload, 'preferredLanguage') &&
    payload.preferredLanguage !== undefined &&
    payload.preferredLanguage !== ''
  ) {
    if (!allowedPreferredLanguages.includes(payload.preferredLanguage)) {
      errors.push('preferredLanguage must be Tamil, Sinhala, or English.');
    }
  }

  if (
    Object.prototype.hasOwnProperty.call(payload, 'interests') &&
    !Array.isArray(payload.interests)
  ) {
    errors.push('interests must be an array.');
  }

  if (Array.isArray(payload.interests)) {
    payload.interests = payload.interests
      .map((interest) => trimString(interest))
      .filter((interest) => typeof interest === 'string' && interest.length > 0);
  }

  return { errors, payload };
}

function getYouthProfilesCollection() {
  return getDatabase().collection(YOUTH_PROFILE_COLLECTION);
}

async function createYouthProfile(req, res) {
  const { errors, payload } = buildProfilePayload(req.body, { isCreate: true });

  if (errors.length > 0) {
    return res.status(400).json({
      error: 'Invalid youth profile',
      messages: errors,
    });
  }

  const now = new Date();
  const profile = {
    ...payload,
    createdAt: now,
    updatedAt: now,
  };

  try {
    const collection = getYouthProfilesCollection();
    const result = await collection.insertOne(profile);

    return res.status(201).json({
      _id: result.insertedId,
      ...profile,
    });
  } catch (error) {
    console.error('Failed to create youth profile:', error.message);

    return res.status(500).json({
      error: 'Unable to create youth profile',
      message: 'An unexpected server error occurred.',
    });
  }
}

async function getYouthProfiles(req, res) {
  try {
    const collection = getYouthProfilesCollection();
    const items = await collection
      .find({}, { projection: youthProfileProjection })
      .sort({ createdAt: -1, _id: -1 })
      .toArray();

    return res.status(200).json({ items });
  } catch (error) {
    console.error('Failed to retrieve youth profiles:', error.message);

    return res.status(500).json({
      error: 'Unable to retrieve youth profiles',
      message: 'An unexpected server error occurred.',
    });
  }
}

async function getYouthProfileById(req, res) {
  const { id } = req.params;

  if (!isValidObjectId(id)) {
    return res.status(400).json({
      error: 'Invalid youth profile id',
      message: 'id must be a valid MongoDB ObjectId.',
    });
  }

  try {
    const collection = getYouthProfilesCollection();
    const profile = await collection.findOne(
      { _id: new ObjectId(id) },
      { projection: youthProfileProjection },
    );

    if (!profile) {
      return res.status(404).json({
        error: 'Youth profile not found',
        message: 'No youth profile exists for the provided id.',
      });
    }

    return res.status(200).json(profile);
  } catch (error) {
    console.error('Failed to retrieve youth profile:', error.message);

    return res.status(500).json({
      error: 'Unable to retrieve youth profile',
      message: 'An unexpected server error occurred.',
    });
  }
}

async function updateYouthProfile(req, res) {
  const { id } = req.params;

  if (!isValidObjectId(id)) {
    return res.status(400).json({
      error: 'Invalid youth profile id',
      message: 'id must be a valid MongoDB ObjectId.',
    });
  }

  const { errors, payload } = buildProfilePayload(req.body, { isCreate: false });

  if (errors.length > 0) {
    return res.status(400).json({
      error: 'Invalid youth profile',
      messages: errors,
    });
  }

  if (Object.keys(payload).length === 0) {
    return res.status(400).json({
      error: 'Invalid youth profile',
      message: 'At least one supported profile field must be provided.',
    });
  }

  payload.updatedAt = new Date();

  try {
    const collection = getYouthProfilesCollection();
    const result = await collection.findOneAndUpdate(
      { _id: new ObjectId(id) },
      { $set: payload },
      {
        projection: youthProfileProjection,
        returnDocument: 'after',
      },
    );

    if (!result) {
      return res.status(404).json({
        error: 'Youth profile not found',
        message: 'No youth profile exists for the provided id.',
      });
    }

    return res.status(200).json(result);
  } catch (error) {
    console.error('Failed to update youth profile:', error.message);

    return res.status(500).json({
      error: 'Unable to update youth profile',
      message: 'An unexpected server error occurred.',
    });
  }
}

async function deleteYouthProfile(req, res) {
  const { id } = req.params;

  if (!isValidObjectId(id)) {
    return res.status(400).json({
      error: 'Invalid youth profile id',
      message: 'id must be a valid MongoDB ObjectId.',
    });
  }

  try {
    const collection = getYouthProfilesCollection();
    const result = await collection.deleteOne({ _id: new ObjectId(id) });

    if (result.deletedCount === 0) {
      return res.status(404).json({
        error: 'Youth profile not found',
        message: 'No youth profile exists for the provided id.',
      });
    }

    return res.status(204).send();
  } catch (error) {
    console.error('Failed to delete youth profile:', error.message);

    return res.status(500).json({
      error: 'Unable to delete youth profile',
      message: 'An unexpected server error occurred.',
    });
  }
}

module.exports = {
  createYouthProfile,
  deleteYouthProfile,
  getYouthProfileById,
  getYouthProfiles,
  updateYouthProfile,
};
