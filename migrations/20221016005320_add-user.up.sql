-- Add up migration script here
CREATE TABLE "users" (
  "id" bigint NOT NULL,
  "username" text,
  "first_name" text NOT NULL,
  "last_name" text,
  PRIMARY KEY ("id")
);
