const CULTURAL_CONTENT_COLLECTION = 'cultural_contents';

const culturalContentProjection = {
  title: 1,
  category: 1,
  language: 1,
  region: 1,
  contributorName: 1,
  description: 1,
  mediaType: 1,
  mediaUrl: 1,
  createdAt: 1,
};

module.exports = {
  CULTURAL_CONTENT_COLLECTION,
  culturalContentProjection,
};
