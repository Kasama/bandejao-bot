-- Add up migration script here
CREATE TABLE "schedules" (
  "chat_id" bigint NOT NULL,
  "user_id" bigint NOT NULL,
  "configuration" text NOT NULL,
  PRIMARY KEY ("chat_id", "configuration")
);
