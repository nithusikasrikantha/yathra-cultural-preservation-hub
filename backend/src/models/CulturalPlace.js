const mongoose = require('mongoose');

const culturalPlaceSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    description: { type: String, required: true, trim: true },
    province: { type: String, required: true, trim: true },
    district: { type: String, required: true, trim: true },
    region: { type: String, default: '', trim: true },
    categories: { type: [String], default: [] },
    latitude: { type: Number, required: true, min: -90, max: 90 },
    longitude: { type: Number, required: true, min: -180, max: 180 },
    tags: { type: [String], default: [] },
    languages: { type: [String], default: [] },
    traditions: { type: [String], default: [] },
    imageUrl: { type: String, default: null },
    relatedStoryIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Story' }],
    storyCount: { type: Number, default: 0, min: 0 },
  },
  { timestamps: true }
);

culturalPlaceSchema.index({ province: 1, district: 1 });
culturalPlaceSchema.index({ categories: 1 });
culturalPlaceSchema.index({ languages: 1 });

module.exports = mongoose.model('CulturalPlace', culturalPlaceSchema);
