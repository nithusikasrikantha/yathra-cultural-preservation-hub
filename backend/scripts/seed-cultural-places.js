const mongoose = require('mongoose');
const crypto = require('node:crypto');
const { mongodbUri } = require('../src/config/env');
const CulturalPlace = require('../src/models/CulturalPlace');
const Story = require('../src/models/Story');
const places = require('./cultural-places.json');

const id = key => new mongoose.Types.ObjectId(
  crypto.createHash('sha256').update(`yathra-demo-v1:${key}`).digest('hex').slice(0, 24),
);

async function run() {
  if (!process.argv.includes('--apply')) {
    console.log(JSON.stringify({ total: places.length, mode: 'dry-run' }, null, 2));
    return;
  }
  if (!mongodbUri) throw new Error('MONGODB_URI is required.');

  await mongoose.connect(mongodbUri, { serverSelectionTimeoutMS: 15000 });
  try {
    let resolvedStoryReferences = 0;
    for (const place of places) {
      const relatedStoryIds = [];
      for (const key of place.relatedStorySeedKeys || []) {
        const storyId = id(key);
        if (await Story.exists({ _id: storyId, isDeleted: false })) {
          relatedStoryIds.push(storyId);
        }
      }
      resolvedStoryReferences += relatedStoryIds.length;
      const { relatedStorySeedKeys, ...fields } = place;
      await CulturalPlace.findOneAndUpdate(
        { name: fields.name, district: fields.district },
        { $set: { ...fields, relatedStoryIds, storyCount: relatedStoryIds.length } },
        { upsert: true, new: true, runValidators: true, setDefaultsOnInsert: true },
      );
    }
    console.log(JSON.stringify({ total: places.length, resolvedStoryReferences }));
  } finally {
    await mongoose.disconnect();
  }
}

if (require.main === module) run().catch(error => {
  console.error('Cultural place seed failed:', error.message);
  process.exitCode = 1;
});

module.exports = { places };
