BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "restring_event" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "racquetId" bigint NOT NULL,
    "stringJobId" bigint NOT NULL,
    "stringDescription" text NOT NULL,
    "materialCategory" text NOT NULL,
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
-- MIGRATION VERSION FOR string_theory
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('string_theory', '20261004203127934', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261004203127934', "timestamp" = now();

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
