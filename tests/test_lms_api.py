import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_lms_learners_crud():
    learner_data = {
        "learnerId": "lrn-test-001",
        "displayName": "Ada Lovelace",
        "email": "ada@titan.edu",
        "cohortId": "cohort-cs-101",
        "currentLevel": 4,
        "totalXp": 1250,
        "metadata": {"preferredLanguage": "en"}
    }
    # Save learner
    res = client.post("/api/v1/lms/learners", json=learner_data)
    assert res.status_code == 200
    assert res.json()["success"] is True

    # Get learner
    res = client.get("/api/v1/lms/learners/lrn-test-001")
    assert res.status_code == 200
    data = res.json()["learner"]
    assert data["displayName"] == "Ada Lovelace"

    # List learners
    res = client.get("/api/v1/lms/learners")
    assert res.status_code == 200
    learners = res.json() if isinstance(res.json(), list) else res.json().get("learners", [])
    assert any(l["learnerId"] == "lrn-test-001" for l in learners)


def test_lms_courses_and_enrollments():
    course_data = {
        "courseId": "crs-cs-101",
        "title": "Algorithms & Data Structures",
        "description": "Foundational CS course",
        "tenantId": "tenant-default",
        "facultyId": "fac-01",
        "status": "active"
    }
    # Save course
    res = client.post("/api/v1/lms/courses", json=course_data)
    assert res.status_code == 200
    assert res.json()["success"] is True

    # Get course
    res = client.get("/api/v1/lms/courses/crs-cs-101?tenantId=tenant-default")
    assert res.status_code == 200
    assert res.json()["course"]["title"] == "Algorithms & Data Structures"

    # Save enrollment
    enrollment_data = {
        "enrollmentId": "enr-001",
        "courseId": "crs-cs-101",
        "learnerId": "lrn-test-001",
        "tenantId": "tenant-default",
        "cohortId": "cohort-cs-101",
        "status": "enrolled"
    }
    res = client.post("/api/v1/lms/enrollments", json=enrollment_data)
    assert res.status_code == 200

    # Get active enrollment
    res = client.get("/api/v1/lms/enrollments/active?learnerId=lrn-test-001&courseId=crs-cs-101&tenantId=tenant-default")
    assert res.status_code == 200
    assert res.json()["enrollment"]["enrollmentId"] == "enr-001"


def test_lms_assessments_and_questions():
    assessment_data = {
        "assessmentId": "asm-cs-101-mid",
        "courseId": "crs-cs-101",
        "title": "Midterm Exam",
        "tenantId": "tenant-default",
        "status": "published",
        "passingScore": 60.0,
        "durationMinutes": 90,
        "questions": [
            {
                "questionId": "q-101",
                "prompt": "What is the time complexity of quicksort average case?",
                "options": ["O(n)", "O(n log n)", "O(n^2)", "O(log n)"],
                "correctIndex": 1,
                "difficulty": "medium",
                "points": 5.0
            }
        ]
    }
    res = client.post("/api/v1/lms/assessments", json=assessment_data)
    assert res.status_code == 200

    # Get assessment
    res = client.get("/api/v1/lms/assessments/asm-cs-101-mid")
    assert res.status_code == 200
    assert res.json()["assessment"]["title"] == "Midterm Exam"

    # Query questions for assessment
    res = client.get("/api/v1/lms/assessments/asm-cs-101-mid/questions")
    assert res.status_code == 200
    assert len(res.json()["questions"]) == 1
    assert res.json()["questions"][0]["questionId"] == "q-101"


def test_lms_attempts_and_results():
    attempt_data = {
        "attemptId": "att-001",
        "assessmentId": "asm-cs-101-mid",
        "learnerId": "lrn-test-001",
        "tenantId": "tenant-default",
        "status": "completed",
        "responses": {"q-101": 1}
    }
    res = client.post("/api/v1/lms/assessments/attempts", json=attempt_data)
    assert res.status_code == 200

    result_data = {
        "resultId": "res-001",
        "attemptId": "att-001",
        "assessmentId": "asm-cs-101-mid",
        "learnerId": "lrn-test-001",
        "score": 95.0,
        "maxScore": 100.0,
        "isPassing": True
    }
    res = client.post("/api/v1/lms/assessments/results", json=result_data)
    assert res.status_code == 200

    # Query result for attempt
    res = client.get("/api/v1/lms/assessments/attempts/att-001/result")
    assert res.status_code == 200
    assert res.json()["result"]["score"] == 95.0


def test_lms_gradebook_and_disputes():
    entry_data = {
        "entryId": "grd-001",
        "assessmentId": "asm-cs-101-mid",
        "learnerId": "lrn-test-001",
        "tenantId": "tenant-default",
        "finalScore": 95.0,
        "letterGrade": "A",
        "publicationStatus": "published"
    }
    res = client.post("/api/v1/lms/gradebook/entries", json=entry_data)
    assert res.status_code == 200

    dispute_data = {
        "disputeId": "dsp-001",
        "entryId": "grd-001",
        "assessmentId": "asm-cs-101-mid",
        "learnerId": "lrn-test-001",
        "reason": "Clarification on question 1 grading",
        "status": "pending"
    }
    res = client.post("/api/v1/lms/gradebook/disputes", json=dispute_data)
    assert res.status_code == 200

    res = client.get("/api/v1/lms/gradebook/disputes/dsp-001")
    assert res.status_code == 200
    assert res.json()["dispute"]["status"] == "pending"


def test_lms_attendance():
    session_data = {
        "sessionId": "att-ses-001",
        "courseId": "crs-cs-101",
        "tenantId": "tenant-default",
        "sessionName": "Lecture 1: Intro to Algorithms",
        "status": "active"
    }
    res = client.post("/api/v1/lms/attendance/sessions", json=session_data)
    assert res.status_code == 200

    record_data = {
        "attendanceId": "rec-001",
        "sessionId": "att-ses-001",
        "learnerId": "lrn-test-001",
        "status": "present"
    }
    res = client.post("/api/v1/lms/attendance/records", json=record_data)
    assert res.status_code == 200

    res = client.get("/api/v1/lms/attendance/sessions/att-ses-001/records")
    assert res.status_code == 200
    assert len(res.json()["records"]) == 1


def test_lms_credentials():
    transcript_data = {
        "transcriptId": "tr-001",
        "learnerId": "lrn-test-001",
        "cohortId": "cohort-cs-101",
        "tenantId": "tenant-default",
        "status": "official",
        "gpa": 3.9,
        "creditsEarned": 30.0
    }
    res = client.post("/api/v1/lms/credentials/transcripts", json=transcript_data)
    assert res.status_code == 200

    cert_data = {
        "certificateId": "cert-001",
        "credentialId": "cred-cs-101-001",
        "learnerId": "lrn-test-001",
        "cohortId": "cohort-cs-101",
        "tenantId": "tenant-default",
        "title": "Certificate of Completion - Computer Science Foundation",
        "status": "issued"
    }
    res = client.post("/api/v1/lms/credentials/certificates", json=cert_data)
    assert res.status_code == 200

    res = client.get("/api/v1/lms/credentials/certificates/by-credential/cred-cs-101-001")
    assert res.status_code == 200
    assert res.json()["certificate"]["title"] == "Certificate of Completion - Computer Science Foundation"


def test_lms_notifications():
    notification_data = {
        "notificationId": "notif-001",
        "recipientId": "lrn-test-001",
        "tenantId": "tenant-default",
        "deduplicationKey": "dedup-cs-101-announce-001",
        "title": "Welcome to CS 101",
        "body": "Class begins Monday morning at 09:00.",
        "type": "announcement",
        "priority": "normal",
        "status": "unread"
    }
    res = client.post("/api/v1/lms/notifications", json=notification_data)
    assert res.status_code == 200

    res = client.get("/api/v1/lms/notifications/unread/count?recipientId=lrn-test-001&tenantId=tenant-default")
    assert res.status_code == 200
    assert res.json()["unreadCount"] >= 1


def test_lms_multi_tenant_isolation():
    # Tenant Alpha writes a course
    client.post("/api/v1/lms/courses", json={
        "courseId": "crs-alpha-001",
        "title": "Alpha Confidential Course",
        "tenantId": "tenant-alpha",
        "status": "active"
    })

    # Tenant Beta attempts to read Tenant Alpha's course -> 403 Forbidden
    res = client.get("/api/v1/lms/courses/crs-alpha-001?tenantId=tenant-beta")
    assert res.status_code == 403

    # Tenant Alpha can access it
    res_alpha = client.get("/api/v1/lms/courses/crs-alpha-001?tenantId=tenant-alpha")
    assert res_alpha.status_code == 200
    assert res_alpha.json()["course"]["title"] == "Alpha Confidential Course"


def test_lms_error_handling_and_status_codes():
    # 404 for non-existent course
    res = client.get("/api/v1/lms/courses/non-existent-course-999")
    assert res.status_code == 404

    # 404 for non-existent assessment
    res = client.get("/api/v1/lms/assessments/non-existent-asm-999")
    assert res.status_code == 404

    # 404 for non-existent certificate
    res = client.get("/api/v1/lms/credentials/certificates/by-credential/non-existent-cred")
    assert res.status_code == 404

    # 400 on invalid payload (missing required field in structured endpoint)
    res = client.post("/api/v1/lms/learners", json={"invalidField": True})
    assert res.status_code in [400, 422]


def test_lms_persistence_roundtrip():
    # Write course and enrollment
    course_res = client.post("/api/v1/lms/courses", json={
        "courseId": "crs-persist-001",
        "title": "Persistent Systems Architecture",
        "tenantId": "tenant-default",
        "status": "active"
    })
    assert course_res.status_code == 200

    # Read back immediately
    read_res = client.get("/api/v1/lms/courses/crs-persist-001?tenantId=tenant-default")
    assert read_res.status_code == 200
    assert read_res.json()["course"]["title"] == "Persistent Systems Architecture"

    # Verify presence in store
    from app.api.v1.lms import lms_store
    assert "crs-persist-001" in lms_store.courses
    assert lms_store.courses["crs-persist-001"]["title"] == "Persistent Systems Architecture"


def test_gemini_server_side_key_safety():
    # Verify that no API endpoint returns server environment secrets in its response
    res = client.get("/api/v1/lms/courses")
    text_content = res.text.lower()
    assert "gemini_api_key" not in text_content
    assert "ai_key" not in text_content
    assert "secret" not in text_content
