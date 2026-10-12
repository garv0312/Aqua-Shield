-- ONLY if you ran an older schema and want a clean start. This DELETES all data in the public schema.
-- Run this first, then run schema.sql. (Users in Authentication > Users are kept.)
drop schema public cascade; create schema public;
grant usage on schema public to postgres, anon, authenticated, service_role;
grant all on schema public to postgres, service_role;
alter default privileges in schema public grant all on tables to postgres, service_role;
alter default privileges in schema public grant all on functions to postgres, service_role;
alter default privileges in schema public grant all on sequences to postgres, service_role;
drop policy if exists lp_ins on storage.objects; drop policy if exists lp_sel on storage.objects; drop policy if exists lp_del on storage.objects;
drop policy if exists kyc_ins on storage.objects; drop policy if exists kyc_sel on storage.objects;
