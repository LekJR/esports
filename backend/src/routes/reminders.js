const express = require('express');
const { query } = require('../db');
const { badRequest, notFound } = require('../httpError');

const router = express.Router();

function mapReminder(row) {
  return {
    id: row.id,
    matchId: row.matchId,
    deviceId: row.deviceId,
    notificationsEnabled: Boolean(row.notificationsEnabled),
    remindBeforeMinutes: row.remindBeforeMinutes,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

async function findReminder(id) {
  const rows = await query(
    `SELECT
       id,
       match_id AS matchId,
       device_id AS deviceId,
       notifications_enabled AS notificationsEnabled,
       remind_before_minutes AS remindBeforeMinutes,
       created_at AS createdAt,
       updated_at AS updatedAt
     FROM reminders
     WHERE id = ?`,
    [id],
  );

  if (rows.length === 0) {
    throw notFound('Reminder not found.');
  }

  return mapReminder(rows[0]);
}

function validateReminderPayload(body, partial = false) {
  const payload = {};

  if (body.matchId === undefined) {
    if (!partial) {
      throw badRequest('matchId is required.');
    }
  } else if (!Number.isInteger(body.matchId) || body.matchId < 1) {
    throw badRequest('matchId must be a positive integer.');
  } else {
    payload.matchId = body.matchId;
  }

  if (body.deviceId === undefined) {
    if (!partial) {
      throw badRequest('deviceId is required.');
    }
  } else if (!body.deviceId || typeof body.deviceId !== 'string') {
    throw badRequest('deviceId is required.');
  } else {
    payload.deviceId = body.deviceId.trim();
  }

  if (body.notificationsEnabled !== undefined) {
    payload.notificationsEnabled = Boolean(body.notificationsEnabled);
  } else if (!partial) {
    payload.notificationsEnabled = true;
  }

  if (body.remindBeforeMinutes !== undefined) {
    if (
      !Number.isInteger(body.remindBeforeMinutes) ||
      body.remindBeforeMinutes < 0 ||
      body.remindBeforeMinutes > 1440
    ) {
      throw badRequest('remindBeforeMinutes must be between 0 and 1440.');
    }
    payload.remindBeforeMinutes = body.remindBeforeMinutes;
  } else if (!partial) {
    payload.remindBeforeMinutes = 10;
  }

  return payload;
}

router.get('/', async (req, res, next) => {
  try {
    const params = [];
    const where = [];

    if (req.query.deviceId) {
      where.push('device_id = ?');
      params.push(req.query.deviceId);
    }

    if (req.query.matchId) {
      where.push('match_id = ?');
      params.push(Number(req.query.matchId));
    }

    const rows = await query(
      `SELECT
         id,
         match_id AS matchId,
         device_id AS deviceId,
         notifications_enabled AS notificationsEnabled,
         remind_before_minutes AS remindBeforeMinutes,
         created_at AS createdAt,
         updated_at AS updatedAt
       FROM reminders
       ${where.length ? `WHERE ${where.join(' AND ')}` : ''}
       ORDER BY created_at DESC`,
      params,
    );

    res.json({ data: rows.map(mapReminder) });
  } catch (error) {
    next(error);
  }
});

router.get('/:id', async (req, res, next) => {
  try {
    const reminder = await findReminder(Number(req.params.id));
    res.json({ data: reminder });
  } catch (error) {
    next(error);
  }
});

router.post('/', async (req, res, next) => {
  try {
    const payload = validateReminderPayload(req.body);

    const matches = await query('SELECT id FROM matches WHERE id = ?', [
      payload.matchId,
    ]);
    if (matches.length === 0) {
      throw notFound('Match not found.');
    }

    await query(
      `INSERT INTO reminders
         (match_id, device_id, notifications_enabled, remind_before_minutes)
       VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE
         notifications_enabled = VALUES(notifications_enabled),
         remind_before_minutes = VALUES(remind_before_minutes),
         updated_at = CURRENT_TIMESTAMP`,
      [
        payload.matchId,
        payload.deviceId,
        payload.notificationsEnabled,
        payload.remindBeforeMinutes,
      ],
    );

    const reminders = await query(
      'SELECT id FROM reminders WHERE match_id = ? AND device_id = ?',
      [payload.matchId, payload.deviceId],
    );

    const reminder = await findReminder(reminders[0].id);

    res.status(201).json({ data: reminder });
  } catch (error) {
    next(error);
  }
});

router.put('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const current = await findReminder(id);
    const payload = validateReminderPayload(req.body, true);

    const nextValues = {
      matchId: payload.matchId ?? current.matchId,
      deviceId: payload.deviceId ?? current.deviceId,
      notificationsEnabled:
        payload.notificationsEnabled ?? current.notificationsEnabled,
      remindBeforeMinutes:
        payload.remindBeforeMinutes ?? current.remindBeforeMinutes,
    };

    const matches = await query('SELECT id FROM matches WHERE id = ?', [
      nextValues.matchId,
    ]);
    if (matches.length === 0) {
      throw notFound('Match not found.');
    }

    await query(
      `UPDATE reminders
       SET match_id = ?,
           device_id = ?,
           notifications_enabled = ?,
           remind_before_minutes = ?
       WHERE id = ?`,
      [
        nextValues.matchId,
        nextValues.deviceId,
        nextValues.notificationsEnabled,
        nextValues.remindBeforeMinutes,
        id,
      ],
    );

    res.json({ data: await findReminder(id) });
  } catch (error) {
    next(error);
  }
});

router.delete('/:id', async (req, res, next) => {
  try {
    const result = await query('DELETE FROM reminders WHERE id = ?', [
      Number(req.params.id),
    ]);

    if (result.affectedRows === 0) {
      throw notFound('Reminder not found.');
    }

    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

module.exports = router;
