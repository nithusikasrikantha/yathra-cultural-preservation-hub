const YOUTH_PROFILE_COLLECTION = 'youth_profiles';

const allowedPreferredLanguages = ['Tamil', 'Sinhala', 'English'];

const youthProfileProjection = {
  name: 1,
  age: 1,
  ageGroup: 1,
  preferredLanguage: 1,
  location: 1,
  interests: 1,
  createdAt: 1,
  updatedAt: 1,
};

module.exports = {
  YOUTH_PROFILE_COLLECTION,
  allowedPreferredLanguages,
  youthProfileProjection,
};
