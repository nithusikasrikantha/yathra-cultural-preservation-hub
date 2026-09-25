const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const storyRoutes = require('./routes/storyRoutes');
const authRoutes = require('./routes/authRoutes');
const { errorHandler, notFound } = require('./middleware/errorMiddleware');
const { nodeEnv } = require('./config/env');

const app = express();

// Security Middleware
app.use(helmet());
app.use(cors());

// Logging Middleware
if (nodeEnv === 'development') {
  app.use(morgan('dev'));
}

// Body Parsing Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// Routes
app.use('/api/stories', storyRoutes);
app.use('/api/auth', authRoutes);

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
