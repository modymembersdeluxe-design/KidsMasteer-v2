#!/usr/bin/env bash
set -euo pipefail

: "${KM_DB_HOST:=127.0.0.1}"
: "${KM_DB_NAME:=kidsmaster}"
: "${KM_DB_USER:=root}"
: "${KM_DB_PASS:=}"

MYSQL_CMD=(mysql -h "$KM_DB_HOST" -u "$KM_DB_USER" "$KM_DB_NAME")
if [[ -n "$KM_DB_PASS" ]]; then
  MYSQL_CMD+=("-p$KM_DB_PASS")
fi

SQL=$(cat <<'SQL_EOF'
CREATE TABLE IF NOT EXISTS encoding_jobs (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  job_type VARCHAR(32) NOT NULL,
  payload_json JSON NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'queued',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO encoding_jobs (job_type, payload_json, status)
VALUES ('thumbnail', JSON_OBJECT('media_id', 1), 'queued');
SELECT id, job_type, status FROM encoding_jobs ORDER BY id DESC LIMIT 1;
SQL_EOF
)

"${MYSQL_CMD[@]}" -e "$SQL"

echo "[PASS] worker smoke inserted test job"
