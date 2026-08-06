from datetime import datetime, timezone

from app.database import build_conversation_record, build_feedback_record


def test_build_conversation_record_contains_expected_fields():
    timestamp = datetime(2026, 8, 6, 12, 0, tzinfo=timezone.utc)

    record = build_conversation_record(
        question="What is my deductible?",
        answer="Please provide your member ID.",
        model="gpt-4.1-mini",
        instructions="You are a helpful assistant.",
        prompt='[{"role": "user", "content": "What is my deductible?"}]',
        prompt_tokens=42,
        completion_tokens=16,
        total_tokens=58,
        response_time=0.84,
        cost=0.00012,
        timestamp=timestamp,
    )

    assert record["question"] == "What is my deductible?"
    assert record["answer"] == "Please provide your member ID."
    assert record["model"] == "gpt-4.1-mini"
    assert record["instructions"] == "You are a helpful assistant."
    assert record["prompt_tokens"] == 42
    assert record["completion_tokens"] == 16
    assert record["total_tokens"] == 58
    assert record["response_time"] == 0.84
    assert record["cost"] == 0.00012
    assert record["timestamp"] == timestamp


def test_build_feedback_record_links_to_conversation():
    timestamp = datetime(2026, 8, 6, 12, 5, tzinfo=timezone.utc)

    record = build_feedback_record(
        conversation_id=7,
        source="ui",
        relevance="high",
        explanation="The answer was directly useful.",
        score=5,
        timestamp=timestamp,
    )

    assert record["conversation_id"] == 7
    assert record["source"] == "ui"
    assert record["relevance"] == "high"
    assert record["explanation"] == "The answer was directly useful."
    assert record["score"] == 5
    assert record["timestamp"] == timestamp
