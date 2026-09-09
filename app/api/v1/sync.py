"""
Sync API v1 Router and Schemas (TITAN-KO-047.0 P47 / P56 Foundation).
Implements the backend endpoint contract for RemoteLearningStateRepository.
"""
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, HTTPException, Query, status
from pydantic import BaseModel, Field

router = APIRouter(tags=["sync"])


# ------------------------------------------------------------------------------
# Pydantic Schemas for Sync Operations
# ------------------------------------------------------------------------------

class SyncEnvelopeSchema(BaseModel):
    sync_id: str = Field(..., alias="syncId")
    learner_id: str = Field(..., alias="learnerId")
    exam_id: str = Field(..., alias="examId")
    client_timestamp: datetime = Field(..., alias="clientTimestamp")
    payload_checksum: str = Field(..., alias="payloadChecksum")
    payload: Dict[str, Any]
    device_id: str = Field(..., alias="deviceId")
    app_version: str = Field(..., alias="appVersion")

    class Config:
        populate_by_name = True


class RemoteSyncResponse(BaseModel):
    success: bool
    remote_revision: Optional[int] = Field(default=None, alias="remoteRevision")
    synced_at: Optional[datetime] = Field(default=None, alias="syncedAt")
    conflict: Optional[Dict[str, Any]] = None
    error_message: Optional[str] = Field(default=None, alias="errorMessage")

    class Config:
        populate_by_name = True


class RemoteFetchResponse(BaseModel):
    success: bool
    exists: bool
    revision: int = 0
    state: Optional[Dict[str, Any]] = None
    error_message: Optional[str] = Field(default=None, alias="errorMessage")

    class Config:
        populate_by_name = True


class SessionCheckpointSchema(BaseModel):
    session_id: str = Field(..., alias="sessionId")
    learner_id: str = Field(..., alias="learnerId")
    exam_id: str = Field(..., alias="examId")
    device_id: str = Field(..., alias="deviceId")
    checkpoint_revision: int = Field(default=0, alias="checkpointRevision")
    payload: Dict[str, Any] = Field(default_factory=dict)

    class Config:
        populate_by_name = True


class RemoteCheckpointResponse(BaseModel):
    success: bool
    remote_revision: Optional[int] = Field(default=None, alias="remoteRevision")
    error_message: Optional[str] = Field(default=None, alias="errorMessage")

    class Config:
        populate_by_name = True


class LearningActivityRecordSchema(BaseModel):
    idempotency_key: str = Field(..., alias="idempotencyKey")
    learner_id: str = Field(..., alias="learnerId")
    exam_id: str = Field(..., alias="examId")
    activity_id: str = Field(..., alias="activityId")
    activity_type: str = Field(..., alias="activityType")
    completed_at: datetime = Field(..., alias="completedAt")
    score: Optional[float] = None
    payload: Optional[Dict[str, Any]] = None

    class Config:
        populate_by_name = True


class PushActivitiesRequest(BaseModel):
    activities: List[LearningActivityRecordSchema]


class PushActivitiesResponse(BaseModel):
    success: bool
    count: int


# ------------------------------------------------------------------------------
# In-Memory Backend Sync Store (Fallback & Local Execution)
# ------------------------------------------------------------------------------

class SyncStore:
    def __init__(self):
        self.states: Dict[str, Dict[str, Any]] = {}
        self.checkpoints: Dict[str, Dict[str, Any]] = {}
        self.activities: Dict[str, Dict[str, Any]] = {}

    def _state_key(self, learner_id: str, exam_id: str) -> str:
        return f"{learner_id.strip()}_{exam_id.strip().lower()}"

    def _checkpoint_key(self, learner_id: str, exam_id: str, session_id: str) -> str:
        return f"{learner_id.strip()}_{exam_id.strip().lower()}_{session_id.strip()}"


sync_store = SyncStore()


# ------------------------------------------------------------------------------
# API Endpoints
# ------------------------------------------------------------------------------

@router.post("/state", response_model=RemoteSyncResponse)
async def push_state(envelope: SyncEnvelopeSchema):
    """
    Pushes an authoritative learner state envelope to remote storage.
    Enforces optimistic concurrency checking.
    """
    key = sync_store._state_key(envelope.learner_id, envelope.exam_id)
    existing = sync_store.states.get(key)
    candidate_revision = envelope.payload.get("revision", 0)

    if existing is not None:
        existing_rev = existing.get("revision", 0)
        if candidate_revision <= existing_rev:
            return RemoteSyncResponse(
                success=False,
                conflict={
                    "conflictId": f"conflict_{envelope.sync_id}",
                    "learnerId": envelope.learner_id,
                    "examId": envelope.exam_id,
                    "localRevision": candidate_revision,
                    "remoteRevision": existing_rev,
                    "reason": "staleRevision",
                },
                errorMessage="Optimistic concurrency conflict: stale revision",
            )

    sync_store.states[key] = envelope.payload
    now = datetime.now(timezone.utc)
    return RemoteSyncResponse(
        success=True,
        remoteRevision=candidate_revision,
        syncedAt=now,
    )


@router.get("/state", response_model=RemoteFetchResponse)
async def fetch_state(
    learner_id: str = Query(..., alias="learnerId"),
    exam_id: str = Query(..., alias="examId"),
):
    """Fetches the latest authoritative learner state for a learner and exam."""
    key = sync_store._state_key(learner_id, exam_id)
    state = sync_store.states.get(key)
    if state is None:
        return RemoteFetchResponse(success=True, exists=False, revision=0)
    return RemoteFetchResponse(
        success=True,
        exists=True,
        revision=state.get("revision", 0),
        state=state,
    )


@router.post("/checkpoint", response_model=RemoteCheckpointResponse)
async def push_checkpoint(checkpoint: SessionCheckpointSchema):
    """Pushes a learning session checkpoint to remote storage."""
    key = sync_store._checkpoint_key(
        checkpoint.learner_id, checkpoint.exam_id, checkpoint.session_id
    )
    existing = sync_store.checkpoints.get(key)
    if existing and existing.get("checkpointRevision", 0) >= checkpoint.checkpoint_revision:
        return RemoteCheckpointResponse(
            success=True,
            remoteRevision=existing.get("checkpointRevision", 0),
        )

    sync_store.checkpoints[key] = checkpoint.model_dump(by_alias=True)
    return RemoteCheckpointResponse(
        success=True,
        remoteRevision=checkpoint.checkpoint_revision,
    )


@router.get("/checkpoint", response_model=Optional[Dict[str, Any]])
async def fetch_checkpoint(
    session_id: str = Query(..., alias="sessionId"),
    learner_id: str = Query(..., alias="learnerId"),
    exam_id: str = Query(..., alias="examId"),
):
    """Fetches an active session checkpoint from remote storage."""
    key = sync_store._checkpoint_key(learner_id, exam_id, session_id)
    return sync_store.checkpoints.get(key)


@router.post("/activities", response_model=PushActivitiesResponse)
async def push_activities(request: PushActivitiesRequest):
    """Idempotently pushes a batch of learning activity completion records."""
    count = 0
    for act in request.activities:
        if act.idempotency_key not in sync_store.activities:
            sync_store.activities[act.idempotency_key] = act.model_dump(by_alias=True)
            count += 1
    return PushActivitiesResponse(success=True, count=count)


@router.get("/activities", response_model=List[Dict[str, Any]])
async def fetch_activities(
    learner_id: str = Query(..., alias="learnerId"),
    exam_id: str = Query(..., alias="examId"),
):
    """Fetches all activity completion records for a given learner and exam."""
    clean_learner = learner_id.strip()
    clean_exam = exam_id.strip().lower()
    return [
        act
        for act in sync_store.activities.values()
        if act.get("learnerId") == clean_learner and act.get("examId") == clean_exam
    ]
