const router = require('express').Router();
const catalog = require('../data/communities.json');
const Membership = require('../models/CommunityMembership');
const authenticate = require('../middleware/authenticate');
router.use(authenticate);
router.get('/', async (req, res, next) => {
  try {
    const [counts, mine] = await Promise.all([
      Membership.aggregate([{ $group: { _id: '$communityId', count: { $sum: 1 } } }]),
      Membership.find({ user: req.user._id }).lean(),
    ]);
    const followed = new Set(mine.map(m => m.communityId));
    const items = catalog.map(c => ({ ...c, membersCount: counts.find(n => n._id === c.id)?.count || 0, isFollowing: followed.has(c.id) }));
    res.json({ items });
  } catch (error) { next(error); }
});
router.put('/:id/follow', async (req, res, next) => {
  try {
    if (!catalog.some(c => c.id === req.params.id)) return res.status(404).json({ message: 'Community not found.' });
    if (typeof req.body.follow !== 'boolean') return res.status(400).json({ message: 'Choose whether to follow this community.' });
    const filter = { user: req.user._id, communityId: req.params.id };
    if (req.body.follow) {
      try { await Membership.updateOne(filter, { $setOnInsert: filter }, { upsert: true }); }
      catch (error) { if (error.code !== 11000) throw error; }
    } else await Membership.deleteOne(filter);
    res.json({ isFollowing: req.body.follow, membersCount: await Membership.countDocuments({ communityId: req.params.id }) });
  } catch (error) { next(error); }
});
module.exports = router;
