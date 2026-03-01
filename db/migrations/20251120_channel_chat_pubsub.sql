CREATE TABLE IF NOT EXISTS chat_messages (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  channel_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  message TEXT NOT NULL,
  country_code CHAR(2) NULL,
  user_avatar VARCHAR(255) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_chat_channel_created (channel_id, created_at)
);
