BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "racquet" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
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
-- ACTION CREATE TABLE
--
CREATE TABLE "string_job" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
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
    ON DELETE NO ACTION
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
    VALUES ('string_theory', '20261002171208637', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261002171208637', "timestamp" = now();

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
