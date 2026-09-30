const mongoose = require('mongoose');
const dns = require('dns');

// Force Node.js to use Google public DNS (8.8.8.8) to resolve SRV records on Windows
try {
  dns.setServers(['8.8.8.8', '8.8.4.4']);
  dns.setDefaultResultOrder('ipv4first');
} catch (_) {}

const connectDB = async (uri) => {
  try {
    const conn = await mongoose.connect(uri);
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`MongoDB Connection Error: ${error.message}`);
    if (error.message.includes('MongoDB Atlas cluster') || error.message.includes('whitelisted')) {
      console.error('\n========================================================================');
      console.error('ACTION REQUIRED: IP Address Not Whitelisted in MongoDB Atlas!');
      console.error('1. Log in to https://cloud.mongodb.com');
      console.error('2. Go to Security -> Network Access');
      console.error('3. Click "+ Add IP Address" and select "ALLOW ACCESS FROM ANYWHERE" (0.0.0.0/0)');
      console.error('========================================================================\n');
    }
    process.exit(1);
  }
};

module.exports = connectDB;
