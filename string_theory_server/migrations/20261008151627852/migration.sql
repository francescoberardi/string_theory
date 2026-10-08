BEGIN;

--
-- HAND-EDITED: empty the four tenant tables before userId changes from bigint
-- to uuid. Hashed int tenants cannot be mapped back to auth UUIDs, so existing
-- tenant rows are discarded (Story 6.3). Auth tables are not touched.
--
TRUNCATE "racquet", "string_job", "session_log", "restring_event" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "racquet" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "racquet" (
    "id" bigserial PRIMARY KEY,
    "userId" uuid NOT NULL,
    "name" text NOT NULL,
    "brand" text,
    "model" text,
    "isPrimary" boolean NOT NULL DEFAULT false,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "activeStringJobId" bigint
);

-- Indexes
CREATE INDEX "racquet_user_id_idx" ON "racquet" USING btree ("userId");

--
-- ACTION DROP TABLE
--
DROP TABLE "restring_event" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "restring_event" (
    "id" bigserial PRIMARY KEY,
    "userId" uuid NOT NULL,
    "racquetId" bigint NOT NULL,
    "stringJobId" bigint NOT NULL,
    "stringDescription" text NOT NULL,
    "materialCategory" text NOT NULL,
    "installedTension" double precision,
    "stringingDate" timestamp without time zone NOT NULL,
    "restringDate" timestamp without time zone NOT NULL,
    "finalCourtHours" double precision NOT NULL,
    "finalDaysActive" bigint NOT NULL,
    "finalHealthScore" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "restring_event_user_id_idx" ON "restring_event" USING btree ("userId");
CREATE INDEX "restring_event_racquet_id_idx" ON "restring_event" USING btree ("racquetId");

--
-- ACTION DROP TABLE
--
DROP TABLE "session_log" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "session_log" (
    "id" bigserial PRIMARY KEY,
    "userId" uuid NOT NULL,
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
CREATE UNIQUE INDEX "session_log_user_external_id_idx" ON "session_log" USING btree ("userId", "externalWorkoutId");

--
-- ACTION DROP TABLE
--
DROP TABLE "string_job" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "string_job" (
    "id" bigserial PRIMARY KEY,
    "userId" uuid NOT NULL,
    "racquetId" bigint NOT NULL,
    "materialCategory" text NOT NULL,
    "brand" text,
    "model" text,
    "stringingDate" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "installedTension" double precision,
    "maxRatedHours" double precision NOT NULL DEFAULT 20.0,
    "totalCourtHours" double precision NOT NULL DEFAULT 0.0,
    "currentHealthScore" bigint NOT NULL DEFAULT 100,
    "isActive" boolean NOT NULL DEFAULT true,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "string_job_user_id_idx" ON "string_job" USING btree ("userId");
CREATE INDEX "string_job_racquet_id_idx" ON "string_job" USING btree ("racquetId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "racquet"
    ADD CONSTRAINT "racquet_fk_0"
    FOREIGN KEY("activeStringJobId")
    REFERENCES "string_job"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "restring_event"
    ADD CONSTRAINT "restring_event_fk_0"
    FOREIGN KEY("racquetId")
    REFERENCES "racquet"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "restring_event"
    ADD CONSTRAINT "restring_event_fk_1"
    FOREIGN KEY("stringJobId")
    REFERENCES "string_job"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

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
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "string_job"
    ADD CONSTRAINT "string_job_fk_0"
    FOREIGN KEY("racquetId")
    REFERENCES "racquet"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR string_theory
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('string_theory', '20261008151627852', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261008151627852', "timestamp" = now();

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
