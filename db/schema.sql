-- KidsMaster v2 base schema (scaffold excerpt)

CREATE TABLE IF NOT EXISTS users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(64) NOT NULL UNIQUE,
  email VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('user','moderator','admin') NOT NULL DEFAULT 'user',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS channels (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  owner_user_id BIGINT NOT NULL,
  channel_name VARCHAR(120) NOT NULL,
  pfp_url VARCHAR(255) NULL,
  banner_url VARCHAR(255) NULL,
  background_url VARCHAR(255) NULL,
  theme ENUM('deluxe','retro','modern') NOT NULL DEFAULT 'deluxe',
  archived TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_channels_owner FOREIGN KEY (owner_user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS media (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  channel_id BIGINT NOT NULL,
  media_type ENUM('video','audio','image','software','game','storage') NOT NULL,
  title VARCHAR(255) NOT NULL,
  path VARCHAR(255) NOT NULL,
  thumbnail VARCHAR(255) NULL,
  hls_url VARCHAR(255) NULL,
  processed TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_media_channel FOREIGN KEY (channel_id) REFERENCES channels(id)
);
