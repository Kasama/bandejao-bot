-- Add down migration script here
ALTER TABLE users
  DROP COLUMN created_at,
  DROP COLUMN updated_at;
