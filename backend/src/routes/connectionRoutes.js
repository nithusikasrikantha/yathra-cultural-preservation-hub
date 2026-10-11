const express = require('express');
const mongoose = require('mongoose');
const Connection = require('../models/Connection');
const User = require('../models/User');
const Story = require('../models/Story');
const authenticate = require('../middleware/authenticate');

const router = express.Router();
router.use(authenticate);
const validId = (value) => mongoose.isValidObjectId(value);
const publicUser = (user) => user && ({
  _id: user._id, name: user.name, role: user.role,
  profileInfo: user.profileInfo,
});
const connectionQuery = () => Connection.find().populate('requester', 'name role profileInfo')
  .populate('receiver', 'name role profileInfo');
const isMember = (connection, id) => connection.requester._id.toString() === id
  || connection.receiver._id.toString() === id;
const acceptedConnection = async (id, userId) => {
  if (!validId(id)) return null;
  const connection = await Connection.findById(id)
    .populate('requester', 'name role profileInfo')
    .populate('receiver', 'name role profileInfo');
  return connection && connection.status === 'accepted' && isMember(connection, userId)
    ? connection : null;
};

router.get('/elders', async (req, res) => {
  const elders = await User.find({ role: 'elder' }).select('name role profileInfo').sort({ name: 1 });
  res.json({ items: elders.map(publicUser) });
});

router.get('/', async (req, res) => {
  const connections = await connectionQuery().find({
    $or: [{ requester: req.user._id }, { receiver: req.user._id }],
  }).sort({ updatedAt: -1 });
  res.json({ items: connections });
});

router.get('/notifications', async (req, res) => {
  if (req.user.role !== 'elder') return res.status(403).json({ message: 'Elder account required.' });
  const items = await connectionQuery().find({ receiver: req.user._id, status: 'pending' })
    .sort({ createdAt: -1 });
  res.json({ items });
});

router.post('/', async (req, res) => {
  if (req.user.role !== 'youth') return res.status(403).json({ message: 'Youth account required.' });
  const { elderId, communityId = '', communityName = '' } = req.body || {};
  if (!validId(elderId)) return res.status(400).json({ message: 'A valid elder is required.' });
  const elder = await User.findOne({ _id: elderId, role: 'elder' });
  if (!elder) return res.status(404).json({ message: 'Elder not found.' });
  if (elder._id.equals(req.user._id)) return res.status(400).json({ message: 'You cannot connect with yourself.' });
  let connection = await Connection.findOne({ requester: req.user._id, receiver: elder._id });
  if (connection && connection.status !== 'rejected') {
    return res.status(200).json({ connection, message: 'A connection request already exists.' });
  }
  if (connection) {
    connection.status = 'pending';
    connection.communityId = String(communityId).slice(0, 120);
    connection.communityName = String(communityName).slice(0, 120);
    connection.messages = [];
    connection.workspace = { title: '', content: '', instructions: '', status: 'draft', storyId: null, updatedAt: new Date() };
    await connection.save();
  } else {
    connection = await Connection.create({
      requester: req.user._id, receiver: elder._id,
      communityId: String(communityId).slice(0, 120),
      communityName: String(communityName).slice(0, 120), status: 'pending',
    });
  }
  res.status(201).json({ connection, message: 'Connection request sent.' });
});

router.put('/:id/status', async (req, res) => {
  if (req.user.role !== 'elder') return res.status(403).json({ message: 'Elder account required.' });
  if (!validId(req.params.id)) return res.status(400).json({ message: 'Invalid connection ID.' });
  const { status } = req.body || {};
  if (!['accepted', 'rejected'].includes(status)) return res.status(400).json({ message: 'Status must be accepted or rejected.' });
  const connection = await Connection.findOne({ _id: req.params.id, receiver: req.user._id, status: 'pending' });
  if (!connection) return res.status(404).json({ message: 'Pending request not found.' });
  connection.status = status;
  await connection.save();
  res.json({ connection, message: `Request ${status}.` });
});

router.get('/:id/messages', async (req, res) => {
  const connection = await acceptedConnection(req.params.id, req.user._id.toString());
  if (!connection) return res.status(404).json({ message: 'Accepted connection not found.' });
  res.json({ items: connection.messages });
});

router.post('/:id/messages', async (req, res) => {
  const connection = await acceptedConnection(req.params.id, req.user._id.toString());
  if (!connection) return res.status(404).json({ message: 'Accepted connection not found.' });
  const text = typeof req.body?.text === 'string' ? req.body.text.trim() : '';
  if (!text || text.length > 4000) return res.status(400).json({ message: 'Message must contain 1 to 4000 characters.' });
  const receiver = connection.requester._id.toString() === req.user._id.toString()
    ? connection.receiver
    : connection.requester;
  connection.messages.push({ sender: req.user._id, receiver, text });
  await connection.save();
  res.status(201).json({ message: connection.messages[connection.messages.length - 1] });
});

router.get('/:id/workspace', async (req, res) => {
  const connection = await acceptedConnection(req.params.id, req.user._id.toString());
  if (!connection) return res.status(404).json({ message: 'Accepted connection not found.' });
  res.json({ connectionId: connection._id, communityId: connection.communityId, communityName: connection.communityName, requester: publicUser(connection.requester), receiver: publicUser(connection.receiver), workspace: connection.workspace });
});

router.put('/:id/workspace', async (req, res) => {
  const connection = await acceptedConnection(req.params.id, req.user._id.toString());
  if (!connection) return res.status(404).json({ message: 'Accepted connection not found.' });
  const { title, content, instructions } = req.body || {};
  for (const [key, value] of Object.entries({ title, content, instructions })) {
    if (value !== undefined && (typeof value !== 'string' || value.length > 20000)) return res.status(400).json({ message: `Invalid ${key}.` });
  }
  connection.workspace.title = typeof title === 'string' ? title.trim() : connection.workspace.title;
  connection.workspace.content = typeof content === 'string' ? content.trim() : connection.workspace.content;
  connection.workspace.instructions = typeof instructions === 'string' ? instructions.trim() : connection.workspace.instructions;
  connection.workspace.updatedAt = new Date();
  await connection.save();
  res.json({ workspace: connection.workspace });
});

router.post('/:id/publish', async (req, res) => {
  const connection = await acceptedConnection(req.params.id, req.user._id.toString());
  if (!connection) return res.status(404).json({ message: 'Accepted connection not found.' });
  const workspace = connection.workspace;
  if (!workspace.title.trim() || !workspace.content.trim()) return res.status(400).json({ message: 'Add a title and cultural content before publishing.' });
  const story = await Story.create({
    title: workspace.title, category: connection.communityName || 'Culture Connect',
    language: connection.requester.profileInfo?.preferredLanguage
      || connection.receiver.profileInfo?.preferredLanguage
      || 'English',
    storyText: [workspace.content, workspace.instructions].filter(Boolean).join('\n\n'),
    tags: ['collaborative', 'culture-connect'], isDeleted: false,
    connection: connection._id, communityId: connection.communityId,
    communityName: connection.communityName, contributors: [connection.requester._id, connection.receiver._id],
    publishedBy: req.user._id,
  });
  connection.workspace.status = 'published';
  connection.workspace.storyId = story._id;
  connection.workspace.updatedAt = new Date();
  await connection.save();
  res.status(201).json({ message: 'Story published.', story });
});

module.exports = router;
