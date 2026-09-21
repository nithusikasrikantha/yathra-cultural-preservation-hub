const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
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

// Health Check Route
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'YATHRA backend API is running',
    timestamp: new Date().toISOString(),
  });
});

// Error Handling
app.use(notFound);
app.use(errorHandler);

module.exports = app;
