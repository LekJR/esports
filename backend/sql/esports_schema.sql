CREATE TABLE IF NOT EXISTS games (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  slug VARCHAR(120) NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS teams (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  game_id INT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  short_name VARCHAR(24),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_teams_game
    FOREIGN KEY (game_id) REFERENCES games(id)
    ON DELETE RESTRICT,
  CONSTRAINT uq_teams_game_name UNIQUE (game_id, name),
  INDEX idx_teams_game_id (game_id)
);

CREATE TABLE IF NOT EXISTS matches (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  game_id INT UNSIGNED NOT NULL,
  team_a_id INT UNSIGNED NOT NULL,
  team_b_id INT UNSIGNED NOT NULL,
  scheduled_at DATETIME NOT NULL,
  status ENUM('scheduled', 'live', 'completed', 'cancelled')
    NOT NULL DEFAULT 'scheduled',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_matches_game
    FOREIGN KEY (game_id) REFERENCES games(id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_matches_team_a
    FOREIGN KEY (team_a_id) REFERENCES teams(id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_matches_team_b
    FOREIGN KEY (team_b_id) REFERENCES teams(id)
    ON DELETE RESTRICT,
  CONSTRAINT chk_matches_distinct_teams CHECK (team_a_id <> team_b_id),
  INDEX idx_matches_scheduled_at (scheduled_at),
  INDEX idx_matches_status (status),
  INDEX idx_matches_game_id (game_id)
);

CREATE TABLE IF NOT EXISTS reminders (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  match_id INT UNSIGNED NOT NULL,
  device_id VARCHAR(191) NOT NULL,
  notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  remind_before_minutes INT UNSIGNED NOT NULL DEFAULT 10,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_reminders_match
    FOREIGN KEY (match_id) REFERENCES matches(id)
    ON DELETE CASCADE,
  CONSTRAINT chk_reminders_before_minutes
    CHECK (remind_before_minutes <= 1440),
  CONSTRAINT uq_reminders_match_device UNIQUE (match_id, device_id),
  INDEX idx_reminders_device_id (device_id)
);

INSERT INTO games (name, slug)
VALUES
  ('Valorant', 'valorant'),
  ('League of Legends', 'league-of-legends'),
  ('Counter-Strike 2', 'counter-strike-2')
ON DUPLICATE KEY UPDATE name = VALUES(name);

INSERT INTO teams (game_id, name, short_name)
SELECT g.id, seed.name, seed.short_name
FROM games g
JOIN (
  SELECT 'valorant' AS game_slug, 'G2 Esports' AS name, 'G2' AS short_name
  UNION ALL SELECT 'valorant', 'NRG', 'NRG'
  UNION ALL SELECT 'valorant', 'T1', 'T1'
  UNION ALL SELECT 'valorant', 'Paper Rex', 'PRX'
  UNION ALL SELECT 'valorant', 'DRX', 'DRX'
  UNION ALL SELECT 'league-of-legends', 'Fnatic', 'FNC'
  UNION ALL SELECT 'league-of-legends', 'Team Liquid', 'TL'
  UNION ALL SELECT 'counter-strike-2', 'MIBR', 'MIB'
) seed ON seed.game_slug = g.slug
ON DUPLICATE KEY UPDATE short_name = VALUES(short_name);
