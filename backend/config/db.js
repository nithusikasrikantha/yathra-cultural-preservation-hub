const { MongoClient } = require('mongodb');

let client;
let database;

async function connectToDatabase() {
  if (database) {
    return database;
  }

  const uri = process.env.MONGODB_URI;

  if (!uri) {
    throw new Error('MONGODB_URI is not configured');
  }

  client = new MongoClient(uri);
  await client.connect();

  database = client.db();
  return database;
}

function getDatabase() {
  if (!database) {
    throw new Error('Database connection has not been initialized');
  }

  return database;
}

async function closeDatabaseConnection() {
  if (client) {
    await client.close();
    client = undefined;
    database = undefined;
  }
}

module.exports = {
  closeDatabaseConnection,
  connectToDatabase,
  getDatabase,
};
