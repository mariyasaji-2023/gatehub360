require('dotenv').config();
const path = require('path');
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');
const authRoutes = require('./routes/auth');
const serviceRoutes = require('./routes/services');
const paymentRoutes = require('./routes/payments');
const societyRoutes = require('./routes/society');
const propertyRoutes = require('./routes/properties');
const hostelRoutes = require('./routes/hostels');
const rentRoutes = require('./routes/rent');

const app = express();

app.use(cors());
app.use(express.json());

app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    console.log(`${req.method} ${req.originalUrl} -> ${res.statusCode} (${Date.now() - start}ms)`);
  });
  next();
});

app.get('/privacy-policy', (req, res) => res.sendFile(path.join(__dirname, 'public', 'privacy-policy.html')));

app.get('/api/health', (req, res) => res.json({ status: 'ok' }));
app.use('/api/auth', authRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/society', societyRoutes);
app.use('/api/properties', propertyRoutes);
app.use('/api/hostels', hostelRoutes);
app.use('/api/my-rent', rentRoutes);

process.on('unhandledRejection', (err) => console.error('Unhandled rejection:', err));

const PORT = process.env.PORT || 5000;

connectDB()
  .then(() => {
    app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
  })
  .catch((err) => {
    console.error('Failed to connect to MongoDB:', err.message);
    process.exit(1);
  });
