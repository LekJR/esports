const express = require('express');
const { query, transaction } = require('../db');
const { badRequest, notFound } = require('../httpError');

const router = express.Router();

const allowedStatuses = new Set(['scheduled', 'live', 'completed', 'cancelled']);

function mapMatch(row) {
  return {
    id: row.id,
    game: {
      id: row.gameId,
      name: row.gameName,
      slug: row.gameSlug,
    },
    teamA: {
      id: row.teamAId,
      name: row.teamAName,
      shortName: row.teamAShortName,
    },
    teamB: {
      id: row.teamBId,
      name: row.teamBName,
      shortName: row.teamBShortName,
    },
    scheduledAt: row.scheduledAt,
    status: row.status,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

async function findMatch(id, connection) {
  const rows = connection
    ? (await connection.execute(matchSelectSql('WHERE m.id = ?'), [id]))[0]
    : await query(matchSelectSql('WHERE m.id = ?'), [id]);

  if (rows.length === 0) {
    throw notFound('Match not found.');
  }

  return mapMatch(rows[0]);
}

function matchSelectSql(where = '') {
  return `
    SELECT
      m.id,
      m.game_id AS gameId,
      g.name AS gameName,
      g.slug AS gameSlug,
      m.team_a_id AS teamAId,
      ta.name AS teamAName,
      ta.short_name AS teamAShortName,
      m.team_b_id AS teamBId,
      tb.name AS teamBName,
      tb.short_name AS teamBShortName,
      m.scheduled_at AS scheduledAt,
      m.status,
      m.created_at AS createdAt,
      m.updated_at AS updatedAt
    FROM matches m
    JOIN games g ON g.id = m.game_id
    JOIN teams ta ON ta.id = m.team_a_id
    JOIN teams tb ON tb.id = m.team_b_id
    ${where}
  `;
}

function validateMatchPayload(body, partial = false) {
  const payload = {};

  for (const field of ['gameId', 'teamAId', 'teamBId']) {
    if (body[field] === undefined) {
      if (!partial) {
        throw badRequest(`${field} is required.`);
      }
      continue;
    }

    if (!Number.isInteger(body[field]) || body[field] < 1) {
      throw badRequest(`${field} must be a positive integer.`);
    }

    payload[field] = body[field];
  }

  if (body.scheduledAt === undefined) {
    if (!partial) {
      throw badRequest('scheduledAt is required.');
    }
  } else {
    const scheduledAt = new Date(body.scheduledAt);
    if (Number.isNaN(scheduledAt.getTime())) {
      throw badRequest('scheduledAt must be a valid date string.');
    }
    payload.scheduledAt = scheduledAt;
  }

  if (body.status !== undefined) {
    if (!allowedStatuses.has(body.status)) {
      throw badRequest(
        'status must be scheduled, live, completed, or cancelled.',
      );
    }
    payload.status = body.status;
  } else if (!partial) {
    payload.status = 'scheduled';
  }

  const teamAId = payload.teamAId ?? body.teamAId;
  const teamBId = payload.teamBId ?? body.teamBId;
  if (teamAId && teamBId && teamAId === teamBId) {
    throw badRequest('teamAId and teamBId must be different teams.');
  }

  return payload;
}

async function assertTeamsBelongToGame(connection, gameId, teamAId, teamBId) {
  const [teams] = await connection.execute(
    `SELECT id
     FROM teams
     WHERE game_id = ? AND id IN (?, ?)`,
    [gameId, teamAId, teamBId],
  );

  if (teams.length !== 2) {
    throw badRequest('Both teams must exist and belong to the selected game.');
  }
}

router.get('/', async (req, res, next) => {
  try {
    const params = [];
    const where = [];

    if (req.query.status) {
      if (!allowedStatuses.has(req.query.status)) {
        throw badRequest(
          'status must be scheduled, live, completed, or cancelled.',
        );
      }
      where.push('m.status = ?');
      params.push(req.query.status);
    }

    if (req.query.gameId) {
      where.push('m.game_id = ?');
      params.push(Number(req.query.gameId));
    }

    const rows = await query(
      `${matchSelectSql(where.length ? `WHERE ${where.join(' AND ')}` : '')}
       ORDER BY m.scheduled_at ASC`,
      params,
    );

    res.json({ data: rows.map(mapMatch) });
  } catch (error) {
    next(error);
  }
});

router.get('/:id', async (req, res, next) => {
  try {
    const match = await findMatch(Number(req.params.id));
    res.json({ data: match });
  } catch (error) {
    next(error);
  }
});

router.post('/', async (req, res, next) => {
  try {
    const payload = validateMatchPayload(req.body);

    const match = await transaction(async (connection) => {
      await assertTeamsBelongToGame(
        connection,
        payload.gameId,
        payload.teamAId,
        payload.teamBId,
      );

      const [result] = await connection.execute(
        `INSERT INTO matches
           (game_id, team_a_id, team_b_id, scheduled_at, status)
         VALUES (?, ?, ?, ?, ?)`,
        [
          payload.gameId,
          payload.teamAId,
          payload.teamBId,
          payload.scheduledAt,
          payload.status,
        ],
      );

      return findMatch(result.insertId, connection);
    });

    res.status(201).json({ data: match });
  } catch (error) {
    next(error);
  }
});

router.put('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const payload = validateMatchPayload(req.body, true);

    const match = await transaction(async (connection) => {
      const current = await findMatch(id, connection);
      const nextValues = {
        gameId: payload.gameId ?? current.game.id,
        teamAId: payload.teamAId ?? current.teamA.id,
        teamBId: payload.teamBId ?? current.teamB.id,
        scheduledAt: payload.scheduledAt ?? new Date(current.scheduledAt),
        status: payload.status ?? current.status,
      };

      if (nextValues.teamAId === nextValues.teamBId) {
        throw badRequest('teamAId and teamBId must be different teams.');
      }

      await assertTeamsBelongToGame(
        connection,
        nextValues.gameId,
        nextValues.teamAId,
        nextValues.teamBId,
      );

      await connection.execute(
        `UPDATE matches
         SET game_id = ?,
             team_a_id = ?,
             team_b_id = ?,
             scheduled_at = ?,
             status = ?
         WHERE id = ?`,
        [
          nextValues.gameId,
          nextValues.teamAId,
          nextValues.teamBId,
          nextValues.scheduledAt,
          nextValues.status,
          id,
        ],
      );

      return findMatch(id, connection);
    });

    res.json({ data: match });
  } catch (error) {
    next(error);
  }
});

router.delete('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const result = await query('DELETE FROM matches WHERE id = ?', [id]);

    if (result.affectedRows === 0) {
      throw notFound('Match not found.');
    }

    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

module.exports = router;
