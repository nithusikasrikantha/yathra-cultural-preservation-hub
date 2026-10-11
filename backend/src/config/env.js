const dotenv = require('dotenv');
const path = require('path');

// Load .env file
dotenv.config({ path: path.join(__dirname, '../../.env') });

const requiredEnvs = [
  'MONGODB_URI',
  'JWT_SECRET',
  'OPENAI_API_KEY',
  'OPENAI_MODEL',
];

const validateEnv = () => {
  const missingEnvs = requiredEnvs.filter((env) => !process.env[env]);

  if (missingEnvs.length > 0) {
    console.error('Missing required environment variables:', missingEnvs.join(', '));
    process.exit(1);
  }
};

module.exports = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: process.env.PORT || 5001,
  mongodbUri: process.env.MONGODB_URI,
  jwtSecret: process.env.JWT_SECRET,
  openaiApiKey: process.env.OPENAI_API_KEY,
  openaiModel: process.env.OPENAI_MODEL,
  validateEnv,
};
