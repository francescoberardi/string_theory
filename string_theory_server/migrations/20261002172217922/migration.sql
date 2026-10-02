BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "racquet" DROP CONSTRAINT IF EXISTS "racquet_fk_0";
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
-- MIGRATION VERSION FOR string_theory
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('string_theory', '20261002172217922', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261002172217922', "timestamp" = now();

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
