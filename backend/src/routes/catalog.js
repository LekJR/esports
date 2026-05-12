const express = require('express');
const { query } = require('../db');
const { badRequest, notFound } = require('../httpError');

const router = express.Router();

router.get('/games', async (req, res, next) => {
  try {
    const games = await query(
      `SELECT id, name, slug, created_at AS createdAt
       FROM games
       ORDER BY name`,
    );
    res.json({ data: games });
  } catch (error) {
    next(error);
  }
});

router.get('/teams', async (req, res, next) => {
  try {
    const params = [];
    const where = [];

    if (req.query.gameId) {
      where.push('t.game_id = ?');
      params.push(Number(req.query.gameId));
    }

    const teams = await query(
      `SELECT
         t.id,
         t.game_id AS gameId,
         g.name AS gameName,
         t.name,
         t.short_name AS shortName,
         t.created_at AS createdAt
       FROM teams t
       JOIN games g ON g.id = t.game_id
       ${where.length ? `WHERE ${where.join(' AND ')}` : ''}
       ORDER BY g.name, t.name`,
      params,
    );

    res.json({ data: teams });
  } catch (error) {
    next(error);
  }
});

router.post('/teams', async (req, res, next) => {
  try {
    const { gameId, name, shortName } = req.body;

    if (!Number.isInteger(gameId) || gameId < 1) {
      throw badRequest('gameId must be a positive integer.');
    }

    if (!name || typeof name !== 'string') {
      throw badRequest('name is required.');
    }

    const games = await query('SELECT id FROM games WHERE id = ?', [gameId]);
    if (games.length === 0) {
      throw notFound('Game not found.');
    }

    const result = await query(
      `INSERT INTO teams (game_id, name, short_name)
       VALUES (?, ?, ?)`,
      [gameId, name.trim(), shortName ? shortName.trim() : null],
    );

    const team = await query(
      `SELECT id, game_id AS gameId, name, short_name AS shortName, created_at AS createdAt
       FROM teams
       WHERE id = ?`,
      [result.insertId],
    );

    res.status(201).json({ data: team[0] });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
