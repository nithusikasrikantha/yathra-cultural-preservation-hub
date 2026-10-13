const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const storyRoutes = require('./routes/storyRoutes');
const authRoutes = require('./routes/authRoutes');
const aiRoutes = require('./routes/aiRoutes');
const connectionRoutes = require('./routes/connectionRoutes');
const { errorHandler, notFound } = require('./middleware/errorMiddleware');
const { nodeEnv } = require('./config/env');

const app = express();
const path = require('path');

// Security Middleware
app.use(helmet());
app.use(cors());

// Logging Middleware
if (nodeEnv === 'development') {
  app.use(morgan('dev'));
}

// Body Parsing Middleware
app.use(express.json({ limit: '4mb' }));
app.use(express.urlencoded({ extended: false }));

// Routes
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));
app.use('/api/images', require('./routes/imageRoutes'));
app.use('/api/communities', require('./routes/communityRoutes'));
app.use('/api/stories', storyRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/connections', connectionRoutes);

// Health Check Route
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'YATHRA backend API is running',
    timestamp: new Date().toISOString(),
  });
});

// Root Endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'YATHRA Backend is running',
  });
});

// Error Handling
app.use(notFound);
app.use(errorHandler);

module.exports = app;
