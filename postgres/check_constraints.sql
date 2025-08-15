-- Create new schema
CREATE SCHEMA IF NOT EXISTS sample_checks;

-- Table 1: With inline unnamed CHECK constraint on column definition
CREATE TABLE IF NOT EXISTS sample_checks.persons (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    age INT CHECK (age >= 0),  -- Unnamed CHECK constraint directly on column
    email TEXT UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Table 2: With named CHECK constraint defined separately in CREATE TABLE
CREATE TABLE IF NOT EXISTS sample_checks.design_sessions (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    project_id UUID,
    organization_id UUID NOT NULL,
    created_by_user_id UUID NOT NULL,
    parent_design_session_id UUID,
    name TEXT NOT NULL,
    created_at TIMESTAMP(3) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT design_sessions_project_or_org_check CHECK ((project_id IS NOT NULL) OR (organization_id IS NOT NULL))
);