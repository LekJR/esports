# Esports Match Reminder API

Node.js + Express REST API backed by MySQL. It is ready for Render or Railway
hosting, with Railway MySQL as the online database.

## REST API

- `GET /health`
- `GET /api/games`
- `GET /api/teams`
- `POST /api/teams`
- `GET /api/matches`
- `GET /api/matches/:id`
- `POST /api/matches`
- `PUT /api/matches/:id`
- `DELETE /api/matches/:id`
- `GET /api/reminders`
- `GET /api/reminders/:id`
- `POST /api/reminders`
- `PUT /api/reminders/:id`
- `DELETE /api/reminders/:id`

## Database Design

The schema in `sql/esports_schema.sql` is normalized:

- `games`: one row per esport title.
- `teams`: belongs to one game.
- `matches`: references one game and two teams.
- `reminders`: references one match and stores one device reminder.

Foreign keys keep references valid. `reminders.match_id` uses `ON DELETE CASCADE`
so deleting a match removes its reminders.

## Local Setup

1. Create a MySQL database named `esports_reminders`.
2. Run `sql/esports_schema.sql` in that database.
3. Copy `.env.example` to `.env` and set your MySQL connection.
4. Install dependencies:

   ```bash
   npm install
   ```

5. Start the API:

   ```bash
   npm run dev
   ```

## Example Requests

Create a match:

```bash
curl -X POST http://localhost:3000/api/matches \
  -H "Content-Type: application/json" \
  -d "{\"gameId\":1,\"teamAId\":1,\"teamBId\":2,\"scheduledAt\":\"2026-05-12T20:00:00Z\"}"
```

Create or update a reminder for a device:

```bash
curl -X POST http://localhost:3000/api/reminders \
  -H "Content-Type: application/json" \
  -d "{\"matchId\":1,\"deviceId\":\"demo-device\",\"notificationsEnabled\":true,\"remindBeforeMinutes\":10}"
```

## Railway MySQL

1. Create a Railway project.
2. Add a MySQL database.
3. Open the MySQL service variables and copy the connection URL.
4. Set that value as `MYSQL_URL` in your API service. `DATABASE_URL` and
   `MYSQL_PUBLIC_URL` are also supported.
5. Run `sql/esports_schema.sql` using Railway's query console or a MySQL client.

## Render Deployment

1. Create a new Web Service from this repository.
2. Set the root directory to `backend`.
3. Use `npm install` as the build command.
4. Use `npm start` as the start command.
5. Add `MYSQL_URL` and `CORS_ORIGIN` environment variables.

## Railway Node Deployment

1. Create a service from this repository.
2. Set the service root directory to `backend`.
3. Add `MYSQL_URL`.
4. Railway will use `npm start`.
