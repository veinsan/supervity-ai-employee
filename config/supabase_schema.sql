-- Supabase schema for the Airtable -> Supabase migration (Workers / Manager_Directory /
-- policy_config only — the tables OP-01 touches). Column names and casing are transcribed
-- from scripts/seed_loader/schema.py and docs/AUTO_BUILD_GUIDE.md §E, not re-derived, so the
-- same "map by exact column name" contract (DATA_FLOW.md §1/§6, ADR-006) holds across both
-- Airtable and Supabase implementations. All identifiers are double-quoted deliberately —
-- unquoted Postgres identifiers fold to lowercase, which would break exact-name matching.
--
-- Onboarding_Tasks / Provisioning_Integration / Peakon_Engagement / "Cases & Audit Log" are
-- deliberately NOT included yet — their Operators (OP-02/OP-03/OP-04) aren't built, and
-- "Cases & Audit Log" specifically has a dependency on TASKS.md 0.0.4 (OP-05's Airtable
-- Interface console) that needs a separate decision before it moves.

create table if not exists "Workers" (
  "Worker_WID" text primary key,
  "Employee_ID" text unique,
  "Legal_Name" text,
  "Preferred_Name" text,
  "Business_Title" text,
  "Job_Profile" text,
  "Job_Family" text,
  "Management_Level" text,
  "Position_ID" text,
  "Manager_Name" text,
  "Manager_WID" text,
  "Cost_Center" text,
  "Location" text,
  "Hire_Date" date,
  "Worker_Type" text,
  "Time_Type" text,
  "FTE" numeric,
  "Email_Work" text
);

-- Worker_WID (not Employee_ID) is the primary key because OP-01's live Typeform intake path
-- generates a fresh Worker_WID and upserts on it (AUTO_BUILD_GUIDE.md §F ASSUMPTION #4) before
-- an Employee_ID necessarily exists; the bulk reseed utility upserts the same table on
-- Employee_ID instead (scripts/seed_loader/schema.py natural_key). Employee_ID is UNIQUE but
-- nullable so both write paths can coexist without conflict.

create table if not exists "Manager_Directory" (
  "Manager_WID" text primary key,
  "Employee_ID" text,
  "Name" text,
  "Email_Work" text,
  "Org" text
);

create table if not exists "policy_config" (
  "field_key" text primary key,
  "category" text,
  "value" text,
  "justification" text
);
