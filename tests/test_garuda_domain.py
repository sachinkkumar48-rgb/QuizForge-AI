"""
Unit tests for GARUDA AI Core Domain Entities, Invariants, and Interfaces.
"""
import pytest
from datetime import datetime, timezone
from app.garuda.domain import (
    ChatMessage,
    ConversationSession,
    GarudaSession,
    LearningProfile,
    MessageRole,
    TopicMastery,
    GarudaException,
    LearningProfileNotFoundException,
    ConversationSessionNotFoundException,
    InvalidMessageException,
    ProviderUnavailableException,
)
from app.garuda.interfaces import (
    ILearningProfileRepository,
    IConversationSessionRepository,
    IAIServiceProvider,
    IKnowledgeStore,
)


def test_chat_message_instantiation_and_helpers():
    msg = ChatMessage(id="m1", role=MessageRole.USER, content="Hello GARUDA")
    assert msg.id == "m1"
    assert msg.role == MessageRole.USER
    assert msg.content == "Hello GARUDA"
    assert msg.is_user() is True
    assert msg.is_assistant() is False


def test_conversation_session_add_message():
    session = ConversationSession(session_id="s1", user_id="u1", title="Polity Revision")
    assert session.get_message_count() == 0
    assert session.get_last_message() is None

    user_msg = ChatMessage(id="m1", role=MessageRole.USER, content="What is Article 21?")
    session.add_message(user_msg)

    assert session.get_message_count() == 1
    assert session.get_last_message() == user_msg


def test_conversation_session_empty_message_raises_exception():
    session = ConversationSession(session_id="s1", user_id="u1", title="Test")
    invalid_msg = ChatMessage(id="m2", role=MessageRole.USER, content="   ")

    with pytest.raises(InvalidMessageException) as exc_info:
        session.add_message(invalid_msg)
    assert exc_info.value.code == "INVALID_MESSAGE"


def test_topic_mastery_calculation_and_weakness():
    topic = TopicMastery(topic_id="t1", topic_name="Fundamental Rights", mastery_score=0.0)
    assert topic.is_weak() is True

    # 1st attempt correct
    topic.update_attempt(is_correct=True)
    assert topic.total_attempts == 1
    assert topic.correct_attempts == 1
    # 0.7 * 1.0 + 0.3 * 1.0 = 1.0
    assert topic.mastery_score == 1.0
    assert topic.is_weak() is False

    # 2nd attempt wrong
    topic.update_attempt(is_correct=False)
    assert topic.total_attempts == 2
    assert topic.correct_attempts == 1
    # 0.7 * (0.5) + 0.3 * (0.0) = 0.35
    assert topic.mastery_score == 0.35
    assert topic.is_weak() is True


def test_learning_profile_mastery_and_topic_filtering():
    profile = LearningProfile(user_id="u100")
    t1 = TopicMastery(topic_id="t1", topic_name="Polity", mastery_score=0.9, total_attempts=5, correct_attempts=5)
    t2 = TopicMastery(topic_id="t2", topic_name="History", mastery_score=0.4, total_attempts=5, correct_attempts=2)

    profile.update_topic(t1)
    profile.update_topic(t2)

    assert profile.overall_mastery == 0.65
    weak_topics = profile.get_weak_topics()
    strong_topics = profile.get_strong_topics()

    assert len(weak_topics) == 1
    assert weak_topics[0].topic_id == "t2"

    assert len(strong_topics) == 1
    assert strong_topics[0].topic_id == "t1"


def test_garuda_session_aggregate():
    conv = ConversationSession(session_id="s1", user_id="u1", title="Session 1")
    prof = LearningProfile(user_id="u1")
    garuda_session = GarudaSession(session_id="s1", user_id="u1", conversation=conv, profile=prof)

    assert garuda_session.is_active() is True
    assert garuda_session.conversation.session_id == "s1"
    assert garuda_session.profile.user_id == "u1"


def test_garuda_domain_exceptions():
    p_exc = LearningProfileNotFoundException("user_999")
    assert p_exc.code == "PROFILE_NOT_FOUND"
    assert "user_999" in str(p_exc)

    s_exc = ConversationSessionNotFoundException("sess_888")
    assert s_exc.code == "SESSION_NOT_FOUND"

    prov_exc = ProviderUnavailableException("Gemini", "Quota exceeded")
    assert prov_exc.code == "PROVIDER_UNAVAILABLE"
    assert "Gemini" in str(prov_exc)
    assert "Quota exceeded" in str(prov_exc)
