-- Add up migration script here
ALTER TABLE users
  ADD created_at timestamp without time zone DEFAULT now(),
  ADD updated_at timestamp without time zone DEFAULT now();
