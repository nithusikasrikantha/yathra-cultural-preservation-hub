const app = require('./app');
const { port, mongodbUri, validateEnv } = require('./config/env');
const connectDB = require('./config/database');

// Validate Environment Variables
validateEnv();

// Connect to Database
connectDB(mongodbUri);

// Start Server
const server = app.listen(port, () => {
  console.log(`Server running in ${process.env.NODE_ENV || 'development'} mode on port ${port}`);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err, promise) => {
  console.log(`Error: ${err.message}`);
  // Close server & exit process
  server.close(() => process.exit(1));
});
