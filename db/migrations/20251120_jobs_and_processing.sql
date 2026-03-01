CREATE TABLE IF NOT EXISTS encoding_jobs (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  media_id BIGINT NULL,
  job_type ENUM('hls','thumbnail','trim','remix') NOT NULL,
  payload_json JSON NOT NULL,
  status ENUM('queued','running','done','failed','canceled') NOT NULL DEFAULT 'queued',
  attempts INT NOT NULL DEFAULT 0,
  error_message TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_encoding_jobs_status_created (status, created_at)
);

ALTER TABLE media
  ADD COLUMN IF NOT EXISTS hls_url VARCHAR(255) NULL,
  ADD COLUMN IF NOT EXISTS duration_seconds INT NULL;
