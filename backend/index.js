require('dotenv').config({ quiet: true });

const express = require('express');

const { connectToDatabase } = require('./config/db');
const culturalContentRoutes = require('./routes/culturalContentRoutes');

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'yathra-backend',
  });
});

app.use('/api/cultural-content', culturalContentRoutes);

async function startServer() {
  try {
    await connectToDatabase();

    app.listen(port, () => {
      console.log(`YATHRA backend running on port ${port}`);
    });
  } catch (error) {
    console.error('Failed to start YATHRA backend:', error.message);
    process.exit(1);
  }
}

if (require.main === module) {
  startServer();
}

module.exports = app;
