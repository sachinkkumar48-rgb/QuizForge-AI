-- ==============================================================================
-- Project TITAN - PostgreSQL Production Database Schema
-- Milestone: P56 Production Backend Foundation
-- ==============================================================================

-- 1. Tenant / Institution Identity Table
CREATE TABLE IF NOT EXISTS tenants (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(64) UNIQUE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_tenants_code ON tenants(code);

-- 2. User Authentication & Identity Table
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    tenant_id VARCHAR(64) REFERENCES tenants(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_tenant ON users(tenant_id);

-- 3. Learner Identity & Academic Profile Table
CREATE TABLE IF NOT EXISTS learners (
    learner_id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tenant_id VARCHAR(64) REFERENCES tenants(id) ON DELETE SET NULL,
    display_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_learners_user ON learners(user_id);
CREATE INDEX IF NOT EXISTS idx_learners_tenant ON learners(tenant_id);

-- 4. Authoritative Learner State Persistence Table (P39 / P47 Sync)
CREATE TABLE IF NOT EXISTS learner_states (
    learner_id VARCHAR(64) NOT NULL,
    exam_id VARCHAR(64) NOT NULL,
    revision INTEGER NOT NULL DEFAULT 0,
    fingerprint VARCHAR(64) NOT NULL,
    payload JSONB NOT NULL,
    synced_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (learner_id, exam_id)
);

CREATE INDEX IF NOT EXISTS idx_learner_states_learner_exam ON learner_states(learner_id, exam_id);

-- 5. Session Checkpoints Table (P40 Session Continuity / P47 Sync)
CREATE TABLE IF NOT EXISTS session_checkpoints (
    session_id VARCHAR(64) NOT NULL,
    learner_id VARCHAR(64) NOT NULL,
    exam_id VARCHAR(64) NOT NULL,
    device_id VARCHAR(64) NOT NULL,
    checkpoint_revision INTEGER NOT NULL DEFAULT 0,
    payload JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (session_id, learner_id, exam_id)
);

CREATE INDEX IF NOT EXISTS idx_checkpoints_lookup ON session_checkpoints(learner_id, exam_id, session_id);

-- 6. Learning Activity Completion Records Table (P43 / P47 Idempotent Log)
CREATE TABLE IF NOT EXISTS learning_activities (
    idempotency_key VARCHAR(128) PRIMARY KEY,
    learner_id VARCHAR(64) NOT NULL,
    exam_id VARCHAR(64) NOT NULL,
    activity_id VARCHAR(64) NOT NULL,
    activity_type VARCHAR(32) NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE NOT NULL,
    score DOUBLE PRECISION,
    payload JSONB,
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_activities_learner_exam ON learning_activities(learner_id, exam_id);
