"""
LMS API v1 Router and Persistence Store (TITAN-KO P49-P54 / P57 Real Backend Integration).
Implements the backend endpoint contract for all institutional LMS domains:
- Learner Profiles
- Courses & Enrollments
- Assessments, Attempts, and Results
- Question Delivery
- Gradebook, Disputes, and Overrides
- Attendance Sessions, Records, and Intervention Signals
- Academic Credentials (Transcripts & Certificates)
- Institutional Notifications
"""
from datetime import datetime, timezone
import hashlib
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, HTTPException, Query, status
from pydantic import BaseModel, Field

router = APIRouter(tags=["lms"])


# ------------------------------------------------------------------------------
# In-Memory / Database Fallback Store for LMS
# ------------------------------------------------------------------------------

class LmsStore:
    def __init__(self):
        self.learners: Dict[str, Dict[str, Any]] = {}
        self.courses: Dict[str, Dict[str, Any]] = {}
        self.enrollments: Dict[str, Dict[str, Any]] = {}
        self.enrollment_audits: List[Dict[str, Any]] = []
        self.assessments: Dict[str, Dict[str, Any]] = {}
        self.attempts: Dict[str, Dict[str, Any]] = {}
        self.results: Dict[str, Dict[str, Any]] = {}
        self.grade_entries: Dict[str, Dict[str, Any]] = {}
        self.grade_disputes: Dict[str, Dict[str, Any]] = {}
        self.grade_overrides: List[Dict[str, Any]] = []
        self.grade_audits: List[Dict[str, Any]] = []
        self.attendance_sessions: Dict[str, Dict[str, Any]] = {}
        self.attendance_records: Dict[str, Dict[str, Any]] = {}
        self.attendance_signals: Dict[str, Dict[str, Any]] = {}
        self.attendance_audits: List[Dict[str, Any]] = []
        self.transcripts: Dict[str, Dict[str, Any]] = {}
        self.certificates: Dict[str, Dict[str, Any]] = {}
        self.credential_audits: List[Dict[str, Any]] = []
        self.notifications: Dict[str, Dict[str, Any]] = {}
        self.notification_audits: List[Dict[str, Any]] = []
        self.questions: Dict[str, Dict[str, Any]] = {}

    def clear(self):
        self.__init__()


lms_store = LmsStore()


# ------------------------------------------------------------------------------
# 1. Learner Identity / Profile Endpoints
# ------------------------------------------------------------------------------

@router.post("/learners")
async def save_learner(payload: Dict[str, Any]):
    learner_id = payload.get("learnerId") or payload.get("id")
    if not learner_id:
        raise HTTPException(status_code=400, detail="Learner ID is required")
    payload["id"] = learner_id
    payload["learnerId"] = learner_id
    lms_store.learners[learner_id] = payload
    return {"success": True, "learner": payload, **payload}


@router.get("/learners/{learner_id}")
async def get_learner(learner_id: str):
    learner = lms_store.learners.get(learner_id)
    if not learner:
        raise HTTPException(status_code=404, detail="Learner not found")
    return {"success": True, "learner": learner, **learner}


@router.get("/learners")
async def list_learners():
    return list(lms_store.learners.values())


# ------------------------------------------------------------------------------
# 2. Courses & Enrollments Endpoints
# ------------------------------------------------------------------------------

@router.post("/courses")
async def save_course(payload: Dict[str, Any]):
    course_id = payload.get("courseId") or payload.get("id")
    if not course_id:
        raise HTTPException(status_code=400, detail="courseId is required")
    payload["courseId"] = course_id
    lms_store.courses[course_id] = payload
    return {"success": True, "course": payload, **payload}


@router.get("/courses/{course_id}")
async def get_course(course_id: str, tenantId: Optional[str] = None):
    course = lms_store.courses.get(course_id)
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    if tenantId and course.get("tenantId") != tenantId:
        raise HTTPException(status_code=403, detail="Tenant boundary violation")
    return {"success": True, "course": course, **course}


@router.get("/courses")
async def list_courses(tenantId: Optional[str] = None, status: Optional[str] = None):
    results = list(lms_store.courses.values())
    if tenantId:
        results = [c for c in results if c.get("tenantId") == tenantId]
    if status:
        results = [c for c in results if c.get("status") == status]
    return results


@router.delete("/courses/{course_id}")
async def delete_course(course_id: str, tenantId: Optional[str] = None):
    course = lms_store.courses.get(course_id)
    if not course:
        return {"success": True}
    if tenantId and course.get("tenantId") != tenantId:
        raise HTTPException(status_code=403, detail="Tenant boundary violation")
    lms_store.courses.pop(course_id, None)
    return {"success": True}


@router.post("/enrollments")
async def save_enrollment(payload: Dict[str, Any]):
    enrollment_id = payload.get("enrollmentId") or payload.get("id")
    if not enrollment_id:
        raise HTTPException(status_code=400, detail="enrollmentId is required")
    payload["enrollmentId"] = enrollment_id
    lms_store.enrollments[enrollment_id] = payload
    return {"success": True, "enrollment": payload, **payload}


@router.get("/enrollments/active")
async def get_active_enrollment(
    learnerId: str = Query(...),
    courseId: str = Query(...),
    tenantId: Optional[str] = None,
):
    for e in lms_store.enrollments.values():
        if e.get("learnerId") == learnerId and e.get("courseId") == courseId:
            if tenantId is None or e.get("tenantId") == tenantId:
                if e.get("status") in ["enrolled", "active"]:
                    return {"success": True, "enrollment": e, **e}
    raise HTTPException(status_code=404, detail="Active enrollment not found")


@router.get("/enrollments/{enrollment_id}")
async def get_enrollment(enrollment_id: str, tenantId: Optional[str] = None):
    enr = lms_store.enrollments.get(enrollment_id)
    if not enr:
        raise HTTPException(status_code=404, detail="Enrollment not found")
    if tenantId and enr.get("tenantId") != tenantId:
        raise HTTPException(status_code=403, detail="Tenant boundary violation")
    return {"success": True, "enrollment": enr, **enr}


@router.get("/enrollments")
async def list_enrollments(
    tenantId: Optional[str] = None,
    courseId: Optional[str] = None,
    cohortId: Optional[str] = None,
    learnerId: Optional[str] = None,
    status: Optional[str] = None,
):
    results = list(lms_store.enrollments.values())
    if tenantId:
        results = [e for e in results if e.get("tenantId") == tenantId]
    if courseId:
        results = [e for e in results if e.get("courseId") == courseId]
    if cohortId:
        results = [e for e in results if e.get("cohortId") == cohortId]
    if learnerId:
        results = [e for e in results if e.get("learnerId") == learnerId]
    if status:
        results = [e for e in results if e.get("status") == status]
    return results


@router.post("/enrollments/audit")
async def save_enrollment_audit(record: Dict[str, Any]):
    lms_store.enrollment_audits.append(record)
    return {"success": True}


@router.get("/enrollments/audit")
async def list_enrollment_audits(
    enrollmentId: Optional[str] = None,
    learnerId: Optional[str] = None,
    tenantId: Optional[str] = None,
):
    results = lms_store.enrollment_audits
    if enrollmentId:
        results = [a for a in results if a.get("enrollmentId") == enrollmentId]
    if learnerId:
        results = [a for a in results if a.get("learnerId") == learnerId]
    if tenantId:
        results = [a for a in results if a.get("tenantId") == tenantId]
    return sorted(results, key=lambda x: x.get("timestamp", ""), reverse=True)


# ------------------------------------------------------------------------------
# 3. Assessments, Attempts, and Results Endpoints
# ------------------------------------------------------------------------------

@router.post("/assessments")
async def save_assessment(payload: Dict[str, Any]):
    assessment_id = payload.get("assessmentId") or payload.get("id")
    if not assessment_id:
        raise HTTPException(status_code=400, detail="assessmentId/id is required")
    payload["id"] = assessment_id
    payload["assessmentId"] = assessment_id
    # If assessment contains embedded questions, index them
    if "questions" in payload and isinstance(payload["questions"], list):
        for q in payload["questions"]:
            qid = q.get("questionId") or q.get("id")
            if qid:
                q["id"] = qid
                q["questionId"] = qid
                lms_store.questions[qid] = q

    lms_store.assessments[assessment_id] = payload
    return {"success": True, "assessment": payload, **payload}


@router.get("/assessments/{assessment_id}/questions")
async def get_assessment_questions(assessment_id: str):
    assessment = lms_store.assessments.get(assessment_id)
    if not assessment:
        raise HTTPException(status_code=404, detail="Assessment not found")
    res = []
    if "questions" in assessment and assessment["questions"]:
        res = assessment["questions"]
    elif "questionIds" in assessment and assessment["questionIds"]:
        for qid in assessment["questionIds"]:
            q = lms_store.questions.get(qid)
            if q:
                res.append(q)
    return {"success": True, "questions": res}


@router.get("/assessments/{assessment_id}")
async def get_assessment(assessment_id: str):
    assessment = lms_store.assessments.get(assessment_id)
    if not assessment:
        raise HTTPException(status_code=404, detail="Assessment not found")
    return {"success": True, "assessment": assessment, **assessment}


@router.get("/assessments")
async def list_assessments(
    tenantId: Optional[str] = None,
    creatorFacultyId: Optional[str] = None,
    cohortId: Optional[str] = None,
    status: Optional[str] = None,
):
    results = list(lms_store.assessments.values())
    if tenantId:
        results = [a for a in results if a.get("tenantId") == tenantId]
    if creatorFacultyId:
        results = [a for a in results if a.get("creatorFacultyId") == creatorFacultyId]
    if cohortId:
        results = [
            a for a in results
            if cohortId in (a.get("cohortIds") or []) or a.get("cohortId") == cohortId
        ]
    if status:
        results = [a for a in results if a.get("status") == status]
    return results


@router.delete("/assessments/{assessment_id}")
async def delete_assessment(assessment_id: str):
    lms_store.assessments.pop(assessment_id, None)
    return {"success": True}


@router.post("/assessments/attempts")
async def save_attempt(payload: Dict[str, Any]):
    attempt_id = payload.get("attemptId") or payload.get("id")
    if not attempt_id:
        raise HTTPException(status_code=400, detail="attemptId is required")
    payload["attemptId"] = attempt_id
    lms_store.attempts[attempt_id] = payload
    return {"success": True, "attempt": payload, **payload}


@router.get("/assessments/attempts/{attempt_id}/result")
async def get_result_for_attempt(attempt_id: str):
    for r in lms_store.results.values():
        if r.get("attemptId") == attempt_id:
            return {"success": True, "result": r, **r}
    raise HTTPException(status_code=404, detail="Result for attempt not found")


@router.get("/assessments/attempts/{attempt_id}")
async def get_attempt(attempt_id: str):
    attempt = lms_store.attempts.get(attempt_id)
    if not attempt:
        raise HTTPException(status_code=404, detail="Attempt not found")
    return {"success": True, "attempt": attempt, **attempt}


@router.get("/assessments/attempts")
async def list_attempts(
    assessmentId: Optional[str] = None,
    learnerId: Optional[str] = None,
    status: Optional[str] = None,
):
    results = list(lms_store.attempts.values())
    if assessmentId:
        results = [a for a in results if a.get("assessmentId") == assessmentId]
    if learnerId:
        results = [a for a in results if a.get("learnerId") == learnerId]
    if status:
        results = [a for a in results if a.get("status") == status]
    return results


@router.post("/assessments/results")
async def save_result(payload: Dict[str, Any]):
    result_id = payload.get("resultId") or payload.get("id")
    if not result_id:
        raise HTTPException(status_code=400, detail="resultId is required")
    payload["resultId"] = result_id
    lms_store.results[result_id] = payload
    return {"success": True, "result": payload, **payload}


@router.get("/assessments/results/{result_id}")
async def get_result(result_id: str):
    res = lms_store.results.get(result_id)
    if not res:
        raise HTTPException(status_code=404, detail="Result not found")
    return {"success": True, "result": res, **res}


@router.get("/assessments/results")
async def list_results(
    assessmentId: Optional[str] = None,
    learnerId: Optional[str] = None,
    attemptId: Optional[str] = None,
):
    results = list(lms_store.results.values())
    if assessmentId:
        results = [r for r in results if r.get("assessmentId") == assessmentId]
    if learnerId:
        results = [r for r in results if r.get("learnerId") == learnerId]
    if attemptId:
        results = [r for r in results if r.get("attemptId") == attemptId]
    return results


# ------------------------------------------------------------------------------
# 4. Question & PYQ Bank Delivery Endpoints
# ------------------------------------------------------------------------------

@router.post("/questions")
async def save_question(payload: Dict[str, Any]):
    qid = payload.get("questionId") or payload.get("id")
    if not qid:
        raise HTTPException(status_code=400, detail="Question id is required")
    payload["id"] = qid
    payload["questionId"] = qid
    lms_store.questions[qid] = payload
    return {"success": True, "question": payload, **payload}


@router.get("/questions/{question_id}")
async def get_question(question_id: str):
    q = lms_store.questions.get(question_id)
    if not q:
        raise HTTPException(status_code=404, detail="Question not found")
    return {"success": True, "question": q, **q}


@router.get("/questions")
async def list_questions(
    subject: Optional[str] = None,
    topic: Optional[str] = None,
    year: Optional[int] = None,
):
    results = list(lms_store.questions.values())
    if subject:
        results = [q for q in results if q.get("subject") == subject]
    if topic:
        results = [q for q in results if q.get("topic") == topic]
    if year:
        results = [q for q in results if q.get("year") == year]
    return results


# ------------------------------------------------------------------------------
# 5. Gradebook Endpoints
# ------------------------------------------------------------------------------

@router.post("/gradebook/entries")
async def save_grade_entry(payload: Dict[str, Any]):
    entry_id = payload.get("entryId") or payload.get("id")
    if not entry_id:
        raise HTTPException(status_code=400, detail="entryId is required")
    payload["entryId"] = entry_id
    lms_store.grade_entries[entry_id] = payload
    return {"success": True, "entry": payload, **payload}


@router.get("/gradebook/entries/by-learner-assessment")
async def get_grade_entry_by_learner_assessment(learnerId: str = Query(...), assessmentId: str = Query(...)):
    for e in lms_store.grade_entries.values():
        if e.get("learnerId") == learnerId and e.get("assessmentId") == assessmentId:
            return {"success": True, "entry": e, **e}
    raise HTTPException(status_code=404, detail="Grade entry not found")


@router.get("/gradebook/entries/{entry_id}")
async def get_grade_entry(entry_id: str):
    entry = lms_store.grade_entries.get(entry_id)
    if not entry:
        raise HTTPException(status_code=404, detail="Grade entry not found")
    return {"success": True, "entry": entry, **entry}


@router.get("/gradebook/entries")
async def list_grade_entries(
    tenantId: Optional[str] = None,
    cohortId: Optional[str] = None,
    assessmentId: Optional[str] = None,
    learnerId: Optional[str] = None,
    publicationStatus: Optional[str] = None,
):
    results = list(lms_store.grade_entries.values())
    if tenantId:
        results = [e for e in results if e.get("tenantId") == tenantId]
    if cohortId:
        results = [e for e in results if e.get("cohortId") == cohortId]
    if assessmentId:
        results = [e for e in results if e.get("assessmentId") == assessmentId]
    if learnerId:
        results = [e for e in results if e.get("learnerId") == learnerId]
    if publicationStatus:
        results = [e for e in results if e.get("publicationStatus") == publicationStatus]
    return results


@router.post("/gradebook/disputes")
async def save_grade_dispute(payload: Dict[str, Any]):
    dispute_id = payload.get("disputeId") or payload.get("id")
    if not dispute_id:
        raise HTTPException(status_code=400, detail="disputeId is required")
    payload["disputeId"] = dispute_id
    lms_store.grade_disputes[dispute_id] = payload
    return {"success": True, "dispute": payload, **payload}


@router.get("/gradebook/disputes/{dispute_id}")
async def get_grade_dispute(dispute_id: str):
    dispute = lms_store.grade_disputes.get(dispute_id)
    if not dispute:
        raise HTTPException(status_code=404, detail="Dispute not found")
    return {"success": True, "dispute": dispute, **dispute}


@router.get("/gradebook/disputes")
async def list_grade_disputes(
    tenantId: Optional[str] = None,
    cohortId: Optional[str] = None,
    assessmentId: Optional[str] = None,
    learnerId: Optional[str] = None,
    status: Optional[str] = None,
):
    results = list(lms_store.grade_disputes.values())
    if tenantId:
        results = [d for d in results if d.get("tenantId") == tenantId]
    if cohortId:
        results = [d for d in results if d.get("cohortId") == cohortId]
    if assessmentId:
        results = [d for d in results if d.get("assessmentId") == assessmentId]
    if learnerId:
        results = [d for d in results if d.get("learnerId") == learnerId]
    if status:
        results = [d for d in results if d.get("status") == status]
    return results


@router.post("/gradebook/overrides")
async def save_grade_override(record: Dict[str, Any]):
    lms_store.grade_overrides.append(record)
    return {"success": True}


@router.get("/gradebook/overrides")
async def list_grade_overrides(
    entryId: Optional[str] = None,
    learnerId: Optional[str] = None,
    assessmentId: Optional[str] = None,
):
    results = lms_store.grade_overrides
    if entryId:
        results = [o for o in results if o.get("entryId") == entryId]
    if learnerId:
        results = [o for o in results if o.get("learnerId") == learnerId]
    if assessmentId:
        results = [o for o in results if o.get("assessmentId") == assessmentId]
    return results


@router.post("/gradebook/audit")
async def save_grade_audit(record: Dict[str, Any]):
    lms_store.grade_audits.append(record)
    return {"success": True}


@router.get("/gradebook/audit")
async def list_grade_audits(
    entryId: Optional[str] = None,
    cohortId: Optional[str] = None,
    learnerId: Optional[str] = None,
):
    results = lms_store.grade_audits
    if entryId:
        results = [a for a in results if a.get("entryId") == entryId]
    if cohortId:
        results = [a for a in results if a.get("cohortId") == cohortId]
    if learnerId:
        results = [a for a in results if a.get("learnerId") == learnerId]
    return sorted(results, key=lambda x: x.get("timestamp", ""), reverse=True)


# ------------------------------------------------------------------------------
# 6. Attendance Endpoints
# ------------------------------------------------------------------------------

@router.post("/attendance/sessions")
async def save_attendance_session(payload: Dict[str, Any]):
    session_id = payload.get("sessionId") or payload.get("id")
    if not session_id:
        raise HTTPException(status_code=400, detail="sessionId is required")
    payload["sessionId"] = session_id
    lms_store.attendance_sessions[session_id] = payload
    return {"success": True, "session": payload, **payload}


@router.get("/attendance/sessions/{session_id}/records")
async def get_session_attendance_records(session_id: str, tenantId: Optional[str] = None):
    results = [r for r in lms_store.attendance_records.values() if r.get("sessionId") == session_id]
    if tenantId:
        results = [r for r in results if r.get("tenantId") == tenantId]
    return {"success": True, "records": results}


@router.get("/attendance/sessions/{session_id}")
async def get_attendance_session(session_id: str, tenantId: Optional[str] = None):
    session = lms_store.attendance_sessions.get(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Attendance session not found")
    if tenantId and session.get("tenantId") != tenantId:
        raise HTTPException(status_code=403, detail="Tenant boundary violation")
    return {"success": True, "session": session, **session}


@router.get("/attendance/sessions")
async def list_attendance_sessions(
    tenantId: Optional[str] = None,
    courseId: Optional[str] = None,
    cohortId: Optional[str] = None,
    status: Optional[str] = None,
):
    results = list(lms_store.attendance_sessions.values())
    if tenantId:
        results = [s for s in results if s.get("tenantId") == tenantId]
    if courseId:
        results = [s for s in results if s.get("courseId") == courseId]
    if cohortId:
        results = [s for s in results if s.get("cohortId") == cohortId]
    if status:
        results = [s for s in results if s.get("status") == status]
    return results


@router.post("/attendance/records")
async def save_attendance_record(payload: Dict[str, Any]):
    record_id = payload.get("attendanceId") or payload.get("recordId") or payload.get("id")
    if not record_id:
        raise HTTPException(status_code=400, detail="attendanceId/recordId is required")
    payload["attendanceId"] = record_id
    payload["recordId"] = record_id
    lms_store.attendance_records[record_id] = payload
    return {"success": True, "record": payload, **payload}


@router.get("/attendance/records/by-session-learner")
async def get_attendance_by_session_learner(
    sessionId: str = Query(...),
    learnerId: str = Query(...),
    tenantId: Optional[str] = None,
):
    for r in lms_store.attendance_records.values():
        if r.get("sessionId") == sessionId and r.get("learnerId") == learnerId:
            if tenantId is None or r.get("tenantId") == tenantId:
                return {"success": True, "record": r, **r}
    raise HTTPException(status_code=404, detail="Attendance record not found")


@router.get("/attendance/records/{record_id}")
async def get_attendance_record(record_id: str, tenantId: Optional[str] = None):
    rec = lms_store.attendance_records.get(record_id)
    if not rec:
        raise HTTPException(status_code=404, detail="Attendance record not found")
    if tenantId and rec.get("tenantId") != tenantId:
        raise HTTPException(status_code=403, detail="Tenant boundary violation")
    return {"success": True, "record": rec, **rec}


@router.get("/attendance/records")
async def list_attendance_records(
    sessionId: Optional[str] = None,
    learnerId: Optional[str] = None,
    courseId: Optional[str] = None,
    tenantId: Optional[str] = None,
):
    results = list(lms_store.attendance_records.values())
    if sessionId:
        results = [r for r in results if r.get("sessionId") == sessionId]
    if learnerId:
        results = [r for r in results if r.get("learnerId") == learnerId]
    if courseId:
        results = [r for r in results if r.get("courseId") == courseId]
    if tenantId:
        results = [r for r in results if r.get("tenantId") == tenantId]
    return results


@router.post("/attendance/signals")
async def save_attendance_signal(payload: Dict[str, Any]):
    signal_id = payload.get("signalId") or payload.get("id")
    if not signal_id:
        raise HTTPException(status_code=400, detail="signalId is required")
    payload["signalId"] = signal_id
    lms_store.attendance_signals[signal_id] = payload
    return {"success": True, "signal": payload, **payload}


@router.get("/attendance/signals/{signal_id}")
async def get_attendance_signal(signal_id: str, tenantId: Optional[str] = None):
    sig = lms_store.attendance_signals.get(signal_id)
    if not sig:
        raise HTTPException(status_code=404, detail="Intervention signal not found")
    if tenantId and sig.get("tenantId") != tenantId:
        raise HTTPException(status_code=403, detail="Tenant boundary violation")
    return {"success": True, "signal": sig, **sig}


@router.get("/attendance/signals")
async def list_attendance_signals(
    tenantId: Optional[str] = None,
    courseId: Optional[str] = None,
    cohortId: Optional[str] = None,
    learnerId: Optional[str] = None,
    status: Optional[str] = None,
):
    results = list(lms_store.attendance_signals.values())
    if tenantId:
        results = [s for s in results if s.get("tenantId") == tenantId]
    if courseId:
        results = [s for s in results if s.get("courseId") == courseId]
    if cohortId:
        results = [s for s in results if s.get("cohortId") == cohortId]
    if learnerId:
        results = [s for s in results if s.get("learnerId") == learnerId]
    if status:
        results = [s for s in results if s.get("status") == status]
    return results


@router.post("/attendance/audit")
async def save_attendance_audit(record: Dict[str, Any]):
    lms_store.attendance_audits.append(record)
    return {"success": True}


@router.get("/attendance/audit")
async def list_attendance_audits(
    sessionId: Optional[str] = None,
    learnerId: Optional[str] = None,
    courseId: Optional[str] = None,
    tenantId: Optional[str] = None,
):
    results = lms_store.attendance_audits
    if sessionId:
        results = [a for a in results if a.get("sessionId") == sessionId]
    if learnerId:
        results = [a for a in results if a.get("learnerId") == learnerId]
    if courseId:
        results = [a for a in results if a.get("courseId") == courseId]
    if tenantId:
        results = [a for a in results if a.get("tenantId") == tenantId]
    return sorted(results, key=lambda x: x.get("timestamp", ""), reverse=True)


# ------------------------------------------------------------------------------
# 7. Credentials (Transcripts & Certificates) Endpoints
# ------------------------------------------------------------------------------

@router.post("/credentials/transcripts")
async def save_transcript(payload: Dict[str, Any]):
    transcript_id = payload.get("transcriptId") or payload.get("id")
    if not transcript_id:
        raise HTTPException(status_code=400, detail="transcriptId is required")
    payload["transcriptId"] = transcript_id
    lms_store.transcripts[transcript_id] = payload
    return {"success": True, "transcript": payload, **payload}


@router.get("/credentials/transcripts/official")
async def get_official_transcript(
    learnerId: str = Query(...),
    cohortId: str = Query(...),
    tenantId: Optional[str] = None,
):
    for t in lms_store.transcripts.values():
        if t.get("learnerId") == learnerId and t.get("cohortId") == cohortId:
            if tenantId is None or t.get("tenantId") == tenantId:
                if t.get("status") == "official":
                    return {"success": True, "transcript": t, **t}
    raise HTTPException(status_code=404, detail="Official transcript not found")


@router.get("/credentials/transcripts/{transcript_id}")
async def get_transcript(transcript_id: str):
    t = lms_store.transcripts.get(transcript_id)
    if not t:
        raise HTTPException(status_code=404, detail="Transcript not found")
    return {"success": True, "transcript": t, **t}


@router.get("/credentials/transcripts")
async def list_transcripts(
    learnerId: Optional[str] = None,
    cohortId: Optional[str] = None,
    tenantId: Optional[str] = None,
    status: Optional[str] = None,
):
    results = list(lms_store.transcripts.values())
    if learnerId:
        results = [t for t in results if t.get("learnerId") == learnerId]
    if cohortId:
        results = [t for t in results if t.get("cohortId") == cohortId]
    if tenantId:
        results = [t for t in results if t.get("tenantId") == tenantId]
    if status:
        results = [t for t in results if t.get("status") == status]
    return results


@router.post("/credentials/certificates")
async def save_certificate(payload: Dict[str, Any]):
    cert_id = payload.get("certificateId") or payload.get("id")
    if not cert_id:
        raise HTTPException(status_code=400, detail="certificateId is required")
    payload["certificateId"] = cert_id

    # Compute tamper-evident SHA-256 fingerprint if absent
    if not payload.get("tamperEvidentFingerprint"):
        fingerprint_content = f"{cert_id}:{payload.get('credentialId')}:{payload.get('learnerId')}:{payload.get('courseId')}"
        payload["tamperEvidentFingerprint"] = hashlib.sha256(fingerprint_content.encode("utf-8")).hexdigest()

    lms_store.certificates[cert_id] = payload
    return {"success": True, "certificate": payload, **payload}


@router.get("/credentials/certificates/by-credential/{credential_id}")
async def get_certificate_by_credential(credential_id: str):
    for cert in lms_store.certificates.values():
        if cert.get("credentialId") == credential_id:
            return {"success": True, "certificate": cert, **cert}
    raise HTTPException(status_code=404, detail="Certificate not found")


@router.get("/credentials/certificates/by-learner-cohort")
async def get_certificate_by_learner_cohort(
    learnerId: str = Query(...),
    cohortId: str = Query(...),
    tenantId: Optional[str] = None,
):
    for cert in lms_store.certificates.values():
        if cert.get("learnerId") == learnerId and cert.get("cohortId") == cohortId:
            if tenantId is None or cert.get("tenantId") == tenantId:
                return {"success": True, "certificate": cert, **cert}
    raise HTTPException(status_code=404, detail="Certificate not found")


@router.get("/credentials/certificates/{certificate_id}")
async def get_certificate(certificate_id: str):
    c = lms_store.certificates.get(certificate_id)
    if not c:
        # Fallback by credentialId
        for cert in lms_store.certificates.values():
            if cert.get("credentialId") == certificate_id:
                return {"success": True, "certificate": cert, **cert}
        raise HTTPException(status_code=404, detail="Certificate not found")
    return {"success": True, "certificate": c, **c}


@router.get("/credentials/certificates")
async def list_certificates(
    learnerId: Optional[str] = None,
    cohortId: Optional[str] = None,
    tenantId: Optional[str] = None,
    status: Optional[str] = None,
):
    results = list(lms_store.certificates.values())
    if learnerId:
        results = [c for c in results if c.get("learnerId") == learnerId]
    if cohortId:
        results = [c for c in results if c.get("cohortId") == cohortId]
    if tenantId:
        results = [c for c in results if c.get("tenantId") == tenantId]
    if status:
        results = [c for c in results if c.get("status") == status]
    return results


@router.get("/credentials/verify/{credential_id}")
async def verify_credential(credential_id: str):
    clean_id = credential_id.strip()
    target_cert = None
    for cert in lms_store.certificates.values():
        if cert.get("credentialId") == clean_id or cert.get("certificateId") == clean_id:
            target_cert = cert
            break

    if not target_cert:
        return {
            "isValid": False,
            "status": "NOT_FOUND",
            "message": f"Credential {clean_id} is not recognized.",
        }

    is_revoked = target_cert.get("status") == "revoked"
    return {
        "isValid": not is_revoked,
        "credentialId": target_cert.get("credentialId"),
        "recipientName": target_cert.get("recipientName") or "Verified Learner",
        "courseTitle": target_cert.get("courseTitle") or target_cert.get("courseId"),
        "issuedAt": target_cert.get("issuedAt"),
        "status": "REVOKED" if is_revoked else "VALID",
        "fingerprint": target_cert.get("tamperEvidentFingerprint"),
    }


@router.post("/credentials/audit")
async def save_credential_audit(record: Dict[str, Any]):
    lms_store.credential_audits.append(record)
    return {"success": True}


@router.get("/credentials/audit")
async def list_credential_audits(
    learnerId: Optional[str] = None,
    targetId: Optional[str] = None,
):
    results = lms_store.credential_audits
    if learnerId:
        results = [a for a in results if a.get("learnerId") == learnerId]
    if targetId:
        results = [a for a in results if a.get("targetId") == targetId]
    return sorted(results, key=lambda x: x.get("timestamp", ""), reverse=True)


# ------------------------------------------------------------------------------
# 8. Institutional Notifications Endpoints
# ------------------------------------------------------------------------------

@router.post("/notifications")
async def save_notification(payload: Dict[str, Any]):
    nid = payload.get("notificationId") or payload.get("id")
    if not nid:
        raise HTTPException(status_code=400, detail="Notification ID is required")
    payload["id"] = nid
    payload["notificationId"] = nid
    dedup = payload.get("deduplicationKey")
    if dedup:
        for existing in lms_store.notifications.values():
            if existing.get("deduplicationKey") == dedup:
                existing.update(payload)
                return {"success": True, "notification": existing, **existing, "deduplicated": True}

    lms_store.notifications[nid] = payload
    return {"success": True, "notification": payload, **payload, "deduplicated": False}


@router.get("/notifications/by-dedup-key/{dedup_key}")
async def get_notification_by_dedup(dedup_key: str, tenantId: Optional[str] = None):
    for n in lms_store.notifications.values():
        if n.get("deduplicationKey") == dedup_key:
            if tenantId is None or n.get("tenantId") == tenantId:
                return {"success": True, "notification": n, **n}
    raise HTTPException(status_code=404, detail="Notification not found")


@router.get("/notifications/unread/count")
@router.get("/notifications/unread-count")
async def count_unread_notifications(
    recipientId: str = Query(...),
    tenantId: Optional[str] = None,
):
    count = 0
    for n in lms_store.notifications.values():
        if n.get("recipientId") == recipientId and n.get("status") == "unread":
            if tenantId is None or n.get("tenantId") == tenantId:
                count += 1
    return {"recipientId": recipientId, "unreadCount": count}


@router.get("/notifications/{notification_id}")
async def get_notification(notification_id: str, tenantId: Optional[str] = None):
    n = lms_store.notifications.get(notification_id)
    if not n:
        raise HTTPException(status_code=404, detail="Notification not found")
    if tenantId and n.get("tenantId") != tenantId:
        raise HTTPException(status_code=403, detail="Tenant boundary violation")
    return {"success": True, "notification": n, **n}


@router.get("/notifications")
async def list_notifications(
    recipientId: str = Query(...),
    tenantId: Optional[str] = None,
    type: Optional[str] = None,
    status: Optional[str] = None,
    priority: Optional[str] = None,
    limit: Optional[int] = None,
):
    results = [n for n in lms_store.notifications.values() if n.get("recipientId") == recipientId]
    if tenantId:
        results = [n for n in results if n.get("tenantId") == tenantId]
    if type:
        results = [n for n in results if n.get("type") == type]
    if status:
        results = [n for n in results if n.get("status") == status]
    if priority:
        results = [n for n in results if n.get("priority") == priority]

    results.sort(key=lambda x: x.get("createdAt", ""), reverse=True)
    if limit and limit > 0:
        results = results[:limit]
    return results


@router.post("/notifications/audit")
async def save_notification_audit(record: Dict[str, Any]):
    lms_store.notification_audits.append(record)
    return {"success": True}


@router.get("/notifications/audit")
async def list_notification_audits(
    recipientId: Optional[str] = None,
    notificationId: Optional[str] = None,
    tenantId: Optional[str] = None,
):
    results = lms_store.notification_audits
    if recipientId:
        results = [a for a in results if a.get("recipientId") == recipientId]
    if notificationId:
        results = [a for a in results if a.get("notificationId") == notificationId]
    if tenantId:
        results = [a for a in results if a.get("tenantId") == tenantId]
    return sorted(results, key=lambda x: x.get("timestamp", ""), reverse=True)


# ------------------------------------------------------------------------------
# 9. Snapshot & Reset Endpoints
# ------------------------------------------------------------------------------

@router.get("/snapshot/export")
async def export_snapshot():
    return {
        "success": True,
        "snapshot": {
            "learners": lms_store.learners,
            "courses": lms_store.courses,
            "enrollments": lms_store.enrollments,
            "enrollment_audits": lms_store.enrollment_audits,
            "assessments": lms_store.assessments,
            "attempts": lms_store.attempts,
            "results": lms_store.results,
            "grade_entries": lms_store.grade_entries,
            "grade_disputes": lms_store.grade_disputes,
            "grade_overrides": lms_store.grade_overrides,
            "grade_audits": lms_store.grade_audits,
            "attendance_sessions": lms_store.attendance_sessions,
            "attendance_records": lms_store.attendance_records,
            "attendance_signals": lms_store.attendance_signals,
            "attendance_audits": lms_store.attendance_audits,
            "transcripts": lms_store.transcripts,
            "certificates": lms_store.certificates,
            "credential_audits": lms_store.credential_audits,
            "notifications": lms_store.notifications,
            "notification_audits": lms_store.notification_audits,
            "questions": lms_store.questions,
        }
    }


@router.post("/snapshot/import")
async def import_snapshot(payload: Dict[str, Any]):
    snap = payload.get("snapshot", payload)
    if "learners" in snap: lms_store.learners = snap["learners"]
    if "courses" in snap: lms_store.courses = snap["courses"]
    if "enrollments" in snap: lms_store.enrollments = snap["enrollments"]
    if "enrollment_audits" in snap: lms_store.enrollment_audits = snap["enrollment_audits"]
    if "assessments" in snap: lms_store.assessments = snap["assessments"]
    if "attempts" in snap: lms_store.attempts = snap["attempts"]
    if "results" in snap: lms_store.results = snap["results"]
    if "grade_entries" in snap: lms_store.grade_entries = snap["grade_entries"]
    if "grade_disputes" in snap: lms_store.grade_disputes = snap["grade_disputes"]
    if "grade_overrides" in snap: lms_store.grade_overrides = snap["grade_overrides"]
    if "grade_audits" in snap: lms_store.grade_audits = snap["grade_audits"]
    if "attendance_sessions" in snap: lms_store.attendance_sessions = snap["attendance_sessions"]
    if "attendance_records" in snap: lms_store.attendance_records = snap["attendance_records"]
    if "attendance_signals" in snap: lms_store.attendance_signals = snap["attendance_signals"]
    if "attendance_audits" in snap: lms_store.attendance_audits = snap["attendance_audits"]
    if "transcripts" in snap: lms_store.transcripts = snap["transcripts"]
    if "certificates" in snap: lms_store.certificates = snap["certificates"]
    if "credential_audits" in snap: lms_store.credential_audits = snap["credential_audits"]
    if "notifications" in snap: lms_store.notifications = snap["notifications"]
    if "notification_audits" in snap: lms_store.notification_audits = snap["notification_audits"]
    if "questions" in snap: lms_store.questions = snap["questions"]
    return {"success": True}


@router.post("/clear")
async def clear_store():
    lms_store.clear()
    return {"success": True}
