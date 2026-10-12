const mongoose = require('mongoose');
const Connection = require('../models/Connection');
const { generateCultureContent, AssistantError } = require('../services/cultureContentAssistantService');

const supported = new Set(['conversation-starters', 'follow-up-questions', 'chat-to-story', 'category-tags']);
const idOf = (value) => value?._id?.toString() || value?.toString();

async function cultureContentAssistantController(req, res) {
  const { action } = req.params;
  if (!supported.has(action)) return res.status(404).json({ message: 'Unknown assistant action.' });
  const connectionId = req.body?.connectionId;
  if (typeof connectionId !== 'string' || !mongoose.isValidObjectId(connectionId)) return res.status(400).json({ message: 'A valid connection is required.' });
  const connection = await Connection.findById(connectionId).populate('requester', 'role profileInfo').populate('receiver', 'role profileInfo');
  const userId = req.user._id.toString();
  const requesterId = idOf(connection?.requester);
  const receiverId = idOf(connection?.receiver);
  const isYouth = req.user.role === 'youth' && requesterId === userId;
  const isElder = req.user.role === 'elder' && receiverId === userId;
  if (!connection || connection.status !== 'accepted' || (!isYouth && !isElder)) return res.status(404).json({ message: 'Accepted connection not found.' });
  if (action === 'chat-to-story' && !isYouth) return res.status(403).json({ message: 'Only the connected youth can create a workspace draft.' });
  if (action === 'chat-to-story' && (!connection.chatConsentYouth || !connection.chatConsentElder)) return res.status(403).json({ message: 'Both the youth and elder must consent before creating a draft from chat.' });

  const body = req.body || {};
  const messages = connection.messages || [];
  const language = String(body.language || req.user.profileInfo?.preferredLanguage || 'English').slice(0, 30);
  let input;
  if (action === 'conversation-starters') {
    input = { community: connection.communityName || 'local cultural knowledge', topic: String(body.topic || connection.communityName || '').slice(0, 180), role: req.user.role };
  } else if (action === 'follow-up-questions') {
    if (!messages.length) return res.status(400).json({ message: 'Start the conversation before asking for follow-up ideas.' });
    input = { community: connection.communityName, conversation: messages.slice(-12).map((m) => ({ speaker: idOf(m.sender) === userId ? 'current user' : 'connected participant', text: m.text })).slice(0, 12) };
  } else if (action === 'chat-to-story') {
    if (!messages.length) return res.status(400).json({ message: 'There are no chat messages to turn into a draft.' });
    input = { community: connection.communityName, conversation: messages.map((m) => ({ speaker: idOf(m.sender) === requesterId ? 'youth' : 'elder', text: m.text })).slice(-60) };
  } else {
    const title = String(body.title || '').trim();
    const content = String(body.content || '').trim();
    if (!content || content.length > 12000 || title.length > 180) return res.status(400).json({ message: 'Add a title and content (up to 12,000 characters) first.' });
    input = { community: connection.communityName, title, description: String(body.description || '').slice(0, 2000), content };
  }

  try {
    const result = await generateCultureContent({ action, input, language });
    return res.json({ success: true, result });
  } catch (error) {
    if (error instanceof AssistantError) {
      if (error.code === 'configuration') return res.status(503).json({ message: 'Culture Assistant setup is incomplete. Add OPENAI_API_KEY and OPENAI_MODEL to backend/.env, then restart the backend.' });
      if (error.code === 'authentication') return res.status(503).json({ message: 'Culture Assistant could not authenticate with OpenAI. Check that OPENAI_API_KEY is a valid, active API key, then restart the backend.' });
      if (error.code === 'rate_limit') return res.status(503).json({ message: 'OpenAI rejected the request because the project reached a usage limit or rate limit. Check API billing and limits, then retry.' });
      if (error.code === 'model') return res.status(503).json({ message: 'OpenAI could not find or access the configured model. Check OPENAI_MODEL and the API project model access.' });
      if (error.code === 'timeout') return res.status(504).json({ message: 'Culture Assistant took too long. Please try again.' });
      return res.status(503).json({ message: 'Culture Assistant is temporarily unavailable. Please try again.' });
    }
    console.error('Culture Content Assistant failed:', error?.name || 'UnknownError');
    return res.status(500).json({ message: 'Culture Assistant could not complete this request.' });
  }
}

module.exports = { cultureContentAssistantController };
