-- Add up migration script here
CREATE TABLE "configurations" (
  "user_id" bigint NOT NULL,
  "restaurant_id" text NOT NULL,
  PRIMARY KEY ("user_id", "restaurant_id")
);
