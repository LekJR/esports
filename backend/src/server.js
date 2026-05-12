require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { pool } = require('./db');
const catalogRoutes = require('./routes/catalog');
const matchRoutes = require('./routes/matches');
const reminderRoutes = require('./routes/reminders');
const { HttpError } = require('./httpError');

const app = express();
const port = Number(process.env.PORT || 3000);
const allowedOrigins = (process.env.CORS_ORIGIN || '*')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

app.use(
  cors({
    origin(origin, callback) {
      if (!origin || allowedOrigins.includes('*') || allowedOrigins.includes(origin)) {
        callback(null, true);
        return;
      }

      callback(new HttpError(403, 'Origin is not allowed by CORS.'));
    },
  }),
);
app.use(express.json());

app.get('/health', async (req, res, next) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok' });
  } catch (error) {
    next(error);
  }
});

app.use('/api', catalogRoutes);
app.use('/api/matches', matchRoutes);
app.use('/api/reminders', reminderRoutes);

app.use((req, res) => {
  res.status(404).json({ error: { message: 'Route not found.' } });
});

app.use((error, req, res, next) => {
  if (res.headersSent) {
    next(error);
    return;
  }

  const statusCode = error.statusCode || 500;
  const message =
    statusCode >= 500 ? 'Unexpected server error.' : error.message;

  if (statusCode >= 500) {
    console.error(error);
  }

  res.status(statusCode).json({ error: { message } });
});

app.listen(port, () => {
  console.log(`Esports API listening on port ${port}`);
});
