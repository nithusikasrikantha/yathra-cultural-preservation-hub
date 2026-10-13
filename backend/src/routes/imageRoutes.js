const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { randomUUID } = require('crypto');
const router = express.Router();
const directory = path.join(__dirname, '../../uploads');
fs.mkdirSync(directory, { recursive: true });
const types = { 'image/jpeg': '.jpg', 'image/png': '.png', 'image/webp': '.webp' };
const upload = multer({
  storage: multer.diskStorage({
    destination: directory,
    filename: (_, file, callback) => callback(null, randomUUID() + types[file.mimetype]),
  }),
  limits: { fileSize: 8 * 1024 * 1024, files: 1 },
  fileFilter: (_, file, callback) => callback(types[file.mimetype] ? null : new Error('Choose a JPG, PNG, or WebP image.'), Boolean(types[file.mimetype])),
}).single('image');
router.post('/', (req, res) => {
  upload(req, res, (error) => {
    if (error) return res.status(400).json({ message: error.code === 'LIMIT_FILE_SIZE' ? 'Images must be smaller than 8 MB.' : error.message });
    if (!req.file) return res.status(400).json({ message: 'Choose an image.' });
    return res.status(201).json({ imageUrl: `/uploads/${req.file.filename}` });
  });
});
module.exports = router;
