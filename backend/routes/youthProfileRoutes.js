const express = require('express');

const {
  createYouthProfile,
  deleteYouthProfile,
  getYouthProfileById,
  getYouthProfiles,
  updateYouthProfile,
} = require('../controllers/youthProfileController');

const router = express.Router();

router.post('/', createYouthProfile);
router.get('/', getYouthProfiles);
router.get('/:id', getYouthProfileById);
router.put('/:id', updateYouthProfile);
router.delete('/:id', deleteYouthProfile);

module.exports = router;
