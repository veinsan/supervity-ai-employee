-- "Cases & Audit Log" is created here as "Cases_Audit_Log" (underscore, no space/ampersand) —
-- the table was still empty (OP-04 not built yet) at migration time, so renaming was free; it
-- avoids the URL-encoding gymnastics ("Cases%20%26%20Audit%20Log") the space/& forced under
-- Airtable.

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

create table if not exists "Onboarding_Tasks" (
  "Event_ID" text primary key,
  "Employee_ID" text,
  "Business_Process" text,
  "Step_Name" text,
  "Milestone" text,
  "Due_Date" date,
  "Status" text,
  "Completed_Date" date,
  "Assigned_To_Role" text
);

create table if not exists "Provisioning_Integration" (
  "Integration_Event_ID" text primary key,
  "Employee_ID" text,
  "Resource" text,
  "Requested_On" date,
  "Status" text,
  "Fulfilled_On" date
);

create table if not exists "Peakon_Engagement" (
  "Response_ID" text primary key,
  "Employee_ID" text,
  "Survey_Round" text,
  "Milestone" text,
  "Driver" text,
  "Score" numeric,
  "Comment" text,
  "Submitted_At" date
);

-- Written at runtime by OP-04 (not CSV-seeded, so not in scripts/seed_loader/schema.py's TABLES
-- list) — case_id is a UUID v4 OP-04 generates per run (AUTO_BUILD_GUIDE.md §F ASSUMPTION #3).
create table if not exists "Cases_Audit_Log" (
  "case_id" text primary key,
  "timestamp" timestamptz,
  "employee_id" text,
  "case_type" text,
  "channel" text,
  "policy_rules_fired" text,
  "outcome" text
);
