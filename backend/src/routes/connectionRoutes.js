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
  .populate('receiver', 'name role profileInfo')
  .select('-workspace.imageDataUri -workspaceItems.imageDataUri');
const isMember = (connection, id) => connection.requester._id.toString() === id
  || connection.receiver._id.toString() === id;
const acceptedConnection = async (id, userId, includeImage = false) => {
  if (!validId(id)) return null;
  let query = Connection.findById(id)
    .populate('requester', 'name role profileInfo')
    .populate('receiver', 'name role profileInfo');
  if (!includeImage) query = query.select('-workspace.imageDataUri');
  const connection = await query;
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
    connection.chatConsentYouth = false;
    connection.chatConsentElder = false;
    connection.workspaceItems = [];
    connection.workspace = { title: '', content: '', instructions: '', contentType: 'Story', language: 'Tamil', tags: [], reviewNote: '', submittedAt: null, reviewedAt: null, status: 'draft', storyId: null, updatedAt: new Date() };
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
  connection.chatConsentYouth = false;
  connection.chatConsentElder = false;
  await connection.save();
  res.status(201).json({ message: connection.messages[connection.messages.length - 1] });
});

router.get('/:id/chat-consent', async (req, res) => {
  const connection = await acceptedConnection(req.params.id, req.user._id.toString());
  if (!connection) return res.status(404).json({ message: 'Accepted connection not found.' });
  res.json({ youth: connection.chatConsentYouth, elder: connection.chatConsentElder });
});

router.put('/:id/chat-consent', async (req, res) => {
  const connection = await acceptedConnection(req.params.id, req.user._id.toString());
  if (!connection) return res.status(404).json({ message: 'Accepted connection not found.' });
  if (typeof req.body?.consent !== 'boolean') return res.status(400).json({ message: 'Choose whether to consent to using this chat.' });
  if (req.user.role === 'youth' && connection.requester._id.toString() === req.user._id.toString()) {
    connection.chatConsentYouth = req.body.consent;
  } else if (req.user.role === 'elder' && connection.receiver._id.toString() === req.user._id.toString()) {
    connection.chatConsentElder = req.body.consent;
  } else {
    return res.status(403).json({ message: 'Only the connected youth and elder can consent.' });
  }
  await connection.save();
  res.json({ youth: connection.chatConsentYouth, elder: connection.chatConsentElder });
});

const workspaceFor = (connection, workspaceItemId) => {
  if (!workspaceItemId || workspaceItemId === 'legacy') return connection.workspace;
  return connection.workspaceItems.id(workspaceItemId) || null;
};

router.post('/:id/workspace/items', async (req, res) => {
  const connection = await acceptedConnection(req.params.id, req.user._id.toString());
  if (!connection) return res.status(404).json({ message: 'Accepted connection not found.' });
  const item = connection.workspaceItems.create({
    contentType: 'Story',
    language: req.user.profileInfo?.preferredLanguage || 'Tamil',
    status: 'draft',
    updatedAt: new Date(),
  });
  connection.workspaceItems.push(item);
  await connection.save();
  res.status(201).json({ item });
});

router.get('/:id/workspace', async (req, res) => {
  const connection = await acceptedConnection(req.params.id, req.user._id.toString(), true);
  if (!connection) return res.status(404).json({ message: 'Accepted connection not found.' });
  const itemId = req.query.workspaceItemId?.toString();
  const workspace = itemId ? workspaceFor(connection, itemId) : connection.workspace;
  if (!workspace) return res.status(404).json({ message: 'Workspace content not found.' });
  res.json({
    connectionId: connection._id,
    communityId: connection.communityId,
    communityName: connection.communityName,
    requester: publicUser(connection.requester),
    receiver: publicUser(connection.receiver),
    workspace,
    workspaceItems: connection.workspaceItems,
  });
});

router.put('/:id/workspace', async (req, res) => {
  const connection = await acceptedConnection(req.params.id, req.user._id.toString(), true);
  if (!connection) return res.status(404).json({ message: 'Accepted connection not found.' });
  const workspace = workspaceFor(connection, req.body?.workspaceItemId);
  if (!workspace) return res.status(404).json({ message: 'Workspace content not found.' });
  const isYouth = req.user.role === 'youth'
    && connection.requester._id.toString() === req.user._id.toString();
  const isElder = req.user.role === 'elder'
    && connection.receiver._id.toString() === req.user._id.toString();
  const mayEdit = (isYouth && ['draft', 'changes_requested'].includes(workspace.status))
    || (isElder && ['draft', 'under_review'].includes(workspace.status));
  if (!mayEdit) return res.status(403).json({ message: 'This contribution cannot be edited in its current review status.' });

  const { title, content, instructions, culturalSignificance, category, imageDataUri, contentType, language, tags } = req.body || {};
  for (const [key, value] of Object.entries({ title, content, instructions, culturalSignificance, category, language })) {
    if (value !== undefined && (typeof value !== 'string' || value.length > 20000)) return res.status(400).json({ message: `Invalid ${key}.` });
  }
  if (imageDataUri !== undefined && (typeof imageDataUri !== 'string' || imageDataUri.length > 2800000 || (imageDataUri && !/^data:image\/(jpeg|png|webp);base64,[A-Za-z0-9+/]+=*$/.test(imageDataUri)))) {
    return res.status(400).json({ message: 'Choose a valid image under 2 MB.' });
  }
  if (contentType !== undefined && !['Story', 'Recipe', 'Tradition', 'Song', 'Festival', 'Other'].includes(contentType)) {
    return res.status(400).json({ message: 'Choose a valid contribution type.' });
  }
  if (tags !== undefined && (!Array.isArray(tags) || tags.length > 12 || tags.some((tag) => typeof tag !== 'string' || tag.trim().length > 40))) {
    return res.status(400).json({ message: 'Tags must contain up to 12 short text values.' });
  }
  workspace.title = typeof title === 'string' ? title.trim() : workspace.title;
  workspace.content = typeof content === 'string' ? content.trim() : workspace.content;
  workspace.instructions = typeof instructions === 'string' ? instructions.trim() : workspace.instructions;
  workspace.culturalSignificance = typeof culturalSignificance === 'string' ? culturalSignificance.trim() : workspace.culturalSignificance;
  workspace.category = typeof category === 'string' ? category.trim() : workspace.category;
  if (typeof imageDataUri === 'string') workspace.imageDataUri = imageDataUri;
  workspace.contentType = contentType || workspace.contentType;
  workspace.language = typeof language === 'string' && language.trim() ? language.trim() : workspace.language;
  if (Array.isArray(tags)) workspace.tags = [...new Set(tags.map((tag) => tag.trim()).filter(Boolean))];
  workspace.updatedAt = new Date();
  await connection.save();
  res.json({ workspace });
});

router.post('/:id/submit', async (req, res) => {
  const connection = await acceptedConnection(req.params.id, req.user._id.toString());
  if (!connection) return res.status(404).json({ message: 'Accepted connection not found.' });
  const isRequester = req.user.role === 'youth'
    && connection.requester._id.toString() === req.user._id.toString();
  if (!isRequester) return res.status(403).json({ message: 'Only the connected youth can submit this contribution for review.' });
  const workspace = workspaceFor(connection, req.body?.workspaceItemId);
  if (!workspace) return res.status(404).json({ message: 'Workspace content not found.' });
  if (!['draft', 'changes_requested'].includes(workspace.status)) {
    return res.status(400).json({ message: 'This contribution is already waiting for review or has been published.' });
  }
  if (!workspace.title.trim() || !workspace.content.trim()) {
    return res.status(400).json({ message: 'Add a title and contribution before sending it for review.' });
  }
  workspace.status = 'under_review';
  workspace.reviewNote = '';
  workspace.submittedAt = new Date();
  workspace.updatedAt = new Date();
  await connection.save();
  res.json({ message: 'Contribution sent to the elder for review.', workspace });
});

router.post('/:id/request-changes', async (req, res) => {
  const connection = await acceptedConnection(req.params.id, req.user._id.toString());
  if (!connection) return res.status(404).json({ message: 'Accepted connection not found.' });
  const isReceiver = req.user.role === 'elder'
    && connection.receiver._id.toString() === req.user._id.toString();
  if (!isReceiver) return res.status(403).json({ message: 'Only the connected elder can request changes.' });
  const workspace = workspaceFor(connection, req.body?.workspaceItemId);
  if (!workspace) return res.status(404).json({ message: 'Workspace content not found.' });
  if (workspace.status !== 'under_review') return res.status(400).json({ message: 'There is no contribution waiting for review.' });
  const note = typeof req.body?.note === 'string' ? req.body.note.trim() : '';
  if (note.length > 2000) return res.status(400).json({ message: 'Review note is too long.' });
  workspace.status = 'changes_requested';
  workspace.reviewNote = note;
  workspace.reviewedAt = new Date();
  workspace.updatedAt = new Date();
  await connection.save();
  res.json({ message: 'Changes requested from the youth.', workspace });
});

router.post('/:id/approve', async (req, res) => {
  const connection = await acceptedConnection(req.params.id, req.user._id.toString());
  if (!connection) return res.status(404).json({ message: 'Accepted connection not found.' });
  const isReceiver = req.user.role === 'elder'
    && connection.receiver._id.toString() === req.user._id.toString();
  if (!isReceiver) return res.status(403).json({ message: 'Only the connected elder can approve this contribution.' });
  const workspace = workspaceFor(connection, req.body?.workspaceItemId);
  if (!workspace) return res.status(404).json({ message: 'Workspace content not found.' });
  if (workspace.status !== 'under_review') return res.status(400).json({ message: 'Only a contribution under review can be approved.' });
  if (!workspace.title.trim() || !workspace.content.trim()) return res.status(400).json({ message: 'Add a title and cultural content before approving.' });
  workspace.status = 'approved';
  workspace.reviewedAt = new Date();
  workspace.updatedAt = new Date();
  await connection.save();
  res.json({ message: 'Contribution approved. It is ready to publish.', workspace });
});

router.post('/:id/publish', async (req, res) => {
  const connection = await acceptedConnection(req.params.id, req.user._id.toString(), true);
  if (!connection) return res.status(404).json({ message: 'Accepted connection not found.' });
  const workspace = workspaceFor(connection, req.body?.workspaceItemId);
  if (!workspace) return res.status(404).json({ message: 'Workspace content not found.' });
  const isReviewingElder = req.user.role === 'elder'
    && connection.receiver._id.toString() === req.user._id.toString();
  if (!isReviewingElder) return res.status(403).json({ message: 'Only the connected elder can publish a reviewed contribution.' });
  if (workspace.status !== 'approved') return res.status(400).json({ message: 'Approve the contribution before publishing.' });
  if (!workspace.title.trim() || !workspace.content.trim()) return res.status(400).json({ message: 'Add a title and cultural content before publishing.' });
  const story = await Story.create({
    title: workspace.title, category: workspace.category || connection.communityName || 'Culture Connect',
    language: workspace.language || connection.requester.profileInfo?.preferredLanguage
      || connection.receiver.profileInfo?.preferredLanguage
      || 'English',
    storyText: [workspace.content, workspace.instructions, workspace.culturalSignificance].filter(Boolean).join('\n\n'),
    imageDataUri: workspace.imageDataUri || '',
    tags: [...new Set(['collaborative', 'culture-connect', (workspace.contentType || 'Story').toLowerCase(), ...(workspace.tags || [])])], isDeleted: false,
    connection: connection._id, communityId: connection.communityId,
    communityName: connection.communityName, contributors: [connection.requester._id, connection.receiver._id],
    publishedBy: req.user._id,
  });
  workspace.status = 'published';
  workspace.storyId = story._id;
  workspace.updatedAt = new Date();
  await connection.save();
  res.status(201).json({ message: 'Story published.', story, workspace });
});

module.exports = router;
