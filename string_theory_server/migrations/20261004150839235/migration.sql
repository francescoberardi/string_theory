BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "session_log" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "racquetId" bigint NOT NULL,
    "startTime" timestamp without time zone NOT NULL,
    "durationMinutes" bigint NOT NULL,
    "courtSurface" text,
    "notes" text,
    "source" text NOT NULL,
    "externalWorkoutId" text,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "session_log_user_id_idx" ON "session_log" USING btree ("userId");
CREATE INDEX "session_log_racquet_id_idx" ON "session_log" USING btree ("racquetId");
CREATE UNIQUE INDEX "session_log_external_id_idx" ON "session_log" USING btree ("externalWorkoutId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "session_log"
    ADD CONSTRAINT "session_log_fk_0"
    FOREIGN KEY("racquetId")
    REFERENCES "racquet"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR string_theory
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('string_theory', '20261004150839235', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261004150839235', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260924105404509', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105404509', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260924105232991', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105232991', "timestamp" = now();


COMMIT;
