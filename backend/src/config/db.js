const mongoose = require('mongoose');

const connectDB = async () => {
  const uri = process.env.MONGODB_URI;

  if (uri && uri.includes('mongodb+srv://')) {
    // Construct direct seedlist URI to completely bypass querySrv DNS lookup failures on Windows/Hotspot
    const directUri = uri
      .replace('mongodb+srv://', 'mongodb://')
      .replace(
        'yathra-cluster.x3cgsho.mongodb.net/',
        'yathra-cluster-shard-00-00.x3cgsho.mongodb.net:27017,yathra-cluster-shard-00-01.x3cgsho.mongodb.net:27017,yathra-cluster-shard-00-02.x3cgsho.mongodb.net:27017/'
      ) + (uri.includes('?') ? '&ssl=true&authSource=admin' : '?ssl=true&authSource=admin');

    try {
      const conn = await mongoose.connect(directUri);
      console.log(`MongoDB Connected: ${conn.connection.host}`);
      return;
    } catch (directErr) {
      // Fallback to original SRV URI if direct fails
      try {
        const conn = await mongoose.connect(uri);
        console.log(`MongoDB Connected: ${conn.connection.host}`);
        return;
      } catch (srvErr) {
        console.error(`MongoDB Connection Error: ${srvErr.message}`);
        process.exit(1);
      }
    }
  }

  try {
    const conn = await mongoose.connect(uri);
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`MongoDB Connection Error: ${error.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;
