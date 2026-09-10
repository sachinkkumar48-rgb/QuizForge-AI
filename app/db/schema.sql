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

-- 7. Courses & Academic Offerings Table (P52)
CREATE TABLE IF NOT EXISTS courses (
    course_id VARCHAR(64) PRIMARY KEY,
    tenant_id VARCHAR(64) NOT NULL DEFAULT 'default_tenant',
    title VARCHAR(255) NOT NULL,
    description TEXT,
    exam_id VARCHAR(64) NOT NULL,
    faculty_id VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'active',
    estimated_hours INTEGER NOT NULL DEFAULT 40,
    payload JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_courses_tenant_status ON courses(tenant_id, status);

-- 8. Learner Course Enrollments & Audit Trail (P52)
CREATE TABLE IF NOT EXISTS enrollments (
    enrollment_id VARCHAR(64) PRIMARY KEY,
    learner_id VARCHAR(64) NOT NULL,
    course_id VARCHAR(64) NOT NULL REFERENCES courses(course_id) ON DELETE CASCADE,
    cohort_id VARCHAR(64),
    tenant_id VARCHAR(64) NOT NULL DEFAULT 'default_tenant',
    status VARCHAR(32) NOT NULL DEFAULT 'active',
    enrolled_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status_updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payload JSONB NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_enrollments_learner ON enrollments(learner_id, tenant_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_course ON enrollments(course_id, status);

CREATE TABLE IF NOT EXISTS enrollment_audits (
    audit_id VARCHAR(64) PRIMARY KEY,
    enrollment_id VARCHAR(64) NOT NULL,
    learner_id VARCHAR(64) NOT NULL,
    course_id VARCHAR(64) NOT NULL,
    tenant_id VARCHAR(64) NOT NULL DEFAULT 'default_tenant',
    action VARCHAR(64) NOT NULL,
    actor_id VARCHAR(64) NOT NULL,
    previous_status VARCHAR(32),
    new_status VARCHAR(32) NOT NULL,
    reason TEXT,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_enrollment_audits_lookup ON enrollment_audits(enrollment_id, learner_id);

-- 9. Assessments, Attempts, and Results (P49)
CREATE TABLE IF NOT EXISTS assessments (
    assessment_id VARCHAR(64) PRIMARY KEY,
    tenant_id VARCHAR(64) NOT NULL DEFAULT 'default_tenant',
    title VARCHAR(255) NOT NULL,
    description TEXT,
    exam_id VARCHAR(64) NOT NULL,
    creator_faculty_id VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'draft',
    max_attempts INTEGER NOT NULL DEFAULT 1,
    payload JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_assessments_tenant_exam ON assessments(tenant_id, exam_id);

CREATE TABLE IF NOT EXISTS assessment_attempts (
    attempt_id VARCHAR(64) PRIMARY KEY,
    assessment_id VARCHAR(64) NOT NULL REFERENCES assessments(assessment_id) ON DELETE CASCADE,
    learner_id VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'in_progress',
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    submitted_at TIMESTAMP WITH TIME ZONE,
    answers JSONB NOT NULL DEFAULT '{}',
    payload JSONB NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_attempts_learner_assessment ON assessment_attempts(learner_id, assessment_id);

CREATE TABLE IF NOT EXISTS assessment_results (
    result_id VARCHAR(64) PRIMARY KEY,
    attempt_id VARCHAR(64) UNIQUE NOT NULL REFERENCES assessment_attempts(attempt_id) ON DELETE CASCADE,
    assessment_id VARCHAR(64) NOT NULL REFERENCES assessments(assessment_id) ON DELETE CASCADE,
    learner_id VARCHAR(64) NOT NULL,
    score DOUBLE PRECISION NOT NULL,
    max_score DOUBLE PRECISION NOT NULL,
    percentage DOUBLE PRECISION NOT NULL,
    is_passed BOOLEAN NOT NULL,
    evaluated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payload JSONB NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_results_learner ON assessment_results(learner_id, assessment_id);

-- 10. Gradebook Entries, Disputes, Overrides & Audit (P50)
CREATE TABLE IF NOT EXISTS gradebook_entries (
    entry_id VARCHAR(64) PRIMARY KEY,
    tenant_id VARCHAR(64) NOT NULL DEFAULT 'default_tenant',
    learner_id VARCHAR(64) NOT NULL,
    assessment_id VARCHAR(64) NOT NULL,
    cohort_id VARCHAR(64),
    raw_score DOUBLE PRECISION NOT NULL,
    max_score DOUBLE PRECISION NOT NULL,
    final_score DOUBLE PRECISION NOT NULL,
    percentage DOUBLE PRECISION NOT NULL,
    letter_grade VARCHAR(8) NOT NULL,
    publication_status VARCHAR(32) NOT NULL DEFAULT 'unpublished',
    payload JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_gradebook_learner ON gradebook_entries(learner_id, assessment_id);

CREATE TABLE IF NOT EXISTS grade_disputes (
    dispute_id VARCHAR(64) PRIMARY KEY,
    entry_id VARCHAR(64) NOT NULL REFERENCES gradebook_entries(entry_id) ON DELETE CASCADE,
    learner_id VARCHAR(64) NOT NULL,
    reason TEXT NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'open',
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS grade_overrides (
    override_id VARCHAR(64) PRIMARY KEY,
    entry_id VARCHAR(64) NOT NULL REFERENCES gradebook_entries(entry_id) ON DELETE CASCADE,
    instructor_id VARCHAR(64) NOT NULL,
    previous_score DOUBLE PRECISION NOT NULL,
    new_score DOUBLE PRECISION NOT NULL,
    rationale TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS grade_audits (
    audit_id VARCHAR(64) PRIMARY KEY,
    entry_id VARCHAR(64) NOT NULL,
    actor_id VARCHAR(64) NOT NULL,
    action VARCHAR(64) NOT NULL,
    details JSONB NOT NULL DEFAULT '{}',
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 11. Attendance Sessions, Records, and Intervention Signals (P53)
CREATE TABLE IF NOT EXISTS attendance_sessions (
    session_id VARCHAR(64) PRIMARY KEY,
    tenant_id VARCHAR(64) NOT NULL DEFAULT 'default_tenant',
    course_id VARCHAR(64) NOT NULL,
    cohort_id VARCHAR(64),
    faculty_id VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'scheduled',
    session_date TIMESTAMP WITH TIME ZONE NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS attendance_records (
    record_id VARCHAR(64) PRIMARY KEY,
    session_id VARCHAR(64) NOT NULL REFERENCES attendance_sessions(session_id) ON DELETE CASCADE,
    learner_id VARCHAR(64) NOT NULL,
    tenant_id VARCHAR(64) NOT NULL DEFAULT 'default_tenant',
    status VARCHAR(32) NOT NULL DEFAULT 'present',
    weight DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    marked_by VARCHAR(64) NOT NULL,
    marked_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remarks TEXT
);

CREATE INDEX IF NOT EXISTS idx_attendance_session_learner ON attendance_records(session_id, learner_id);

CREATE TABLE IF NOT EXISTS attendance_signals (
    signal_id VARCHAR(64) PRIMARY KEY,
    tenant_id VARCHAR(64) NOT NULL DEFAULT 'default_tenant',
    learner_id VARCHAR(64) NOT NULL,
    course_id VARCHAR(64) NOT NULL,
    signal_type VARCHAR(64) NOT NULL,
    severity VARCHAR(32) NOT NULL DEFAULT 'medium',
    details TEXT,
    status VARCHAR(32) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 12. Academic Credentials, Transcripts & Certificates (P51)
CREATE TABLE IF NOT EXISTS academic_transcripts (
    transcript_id VARCHAR(64) PRIMARY KEY,
    tenant_id VARCHAR(64) NOT NULL DEFAULT 'default_tenant',
    learner_id VARCHAR(64) NOT NULL,
    cohort_id VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'official',
    issued_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payload JSONB NOT NULL DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS completion_certificates (
    certificate_id VARCHAR(64) PRIMARY KEY,
    credential_id VARCHAR(64) UNIQUE NOT NULL,
    tenant_id VARCHAR(64) NOT NULL DEFAULT 'default_tenant',
    learner_id VARCHAR(64) NOT NULL,
    course_id VARCHAR(64) NOT NULL,
    cohort_id VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'active',
    tamper_evident_fingerprint VARCHAR(128) NOT NULL,
    issued_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP WITH TIME ZONE,
    payload JSONB NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_certificates_credential_id ON completion_certificates(credential_id);

CREATE TABLE IF NOT EXISTS credential_audits (
    audit_id VARCHAR(64) PRIMARY KEY,
    target_id VARCHAR(64) NOT NULL,
    learner_id VARCHAR(64) NOT NULL,
    action VARCHAR(64) NOT NULL,
    actor_id VARCHAR(64) NOT NULL,
    details JSONB NOT NULL DEFAULT '{}',
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 13. Institutional Notifications & Push Delivery Records (P54)
CREATE TABLE IF NOT EXISTS notifications (
    notification_id VARCHAR(64) PRIMARY KEY,
    deduplication_key VARCHAR(128) UNIQUE,
    tenant_id VARCHAR(64) NOT NULL DEFAULT 'default_tenant',
    recipient_id VARCHAR(64) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(64) NOT NULL,
    priority VARCHAR(32) NOT NULL DEFAULT 'normal',
    status VARCHAR(32) NOT NULL DEFAULT 'unread',
    is_delivered BOOLEAN NOT NULL DEFAULT FALSE,
    payload JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON notifications(recipient_id, status);
