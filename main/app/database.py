import os
import logging
from pathlib import Path
from datetime import datetime, timezone

from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError

logger = logging.getLogger(__name__)

load_dotenv()

DATABASE_URL = (
    f"postgresql://"
    f"{os.getenv('POSTGRES_USER')}:"
    f"{os.getenv('POSTGRES_PASSWORD')}@"
    f"{os.getenv('POSTGRES_HOST')}:"
    f"{os.getenv('POSTGRES_PORT')}/"
    f"{os.getenv('POSTGRES_DB')}"
)

logger.info(
    "Initializing database connection. Host: %s, Database: %s",
    os.getenv("POSTGRES_HOST"),
    os.getenv("POSTGRES_DB")
)

try:
    engine = create_engine(
        DATABASE_URL,
        pool_pre_ping=True
    )

    logger.info("Database engine created successfully")

except SQLAlchemyError:
    logger.exception("Failed to create database engine")
    raise

BASE_DIR = Path(__file__).resolve().parent.parent


def initialize_database():
    sql_file = BASE_DIR / "scripts" / "init_postgres_db.sql"

    with open(sql_file, "r", encoding="utf-8") as f:
        sql = f.read()

    with engine.begin() as conn:
        conn.execute(text(sql))

    logger.info("Database schema initialization completed")


def build_conversation_record(
    question: str,
    answer: str,
    model: str,
    instructions: str,
    prompt: str,
    prompt_tokens: int,
    completion_tokens: int,
    total_tokens: int,
    response_time: float,
    cost: float,
    timestamp: datetime | None = None,
) -> dict:
    return {
        "question": question,
        "answer": answer,
        "model": model,
        "instructions": instructions,
        "prompt": prompt,
        "prompt_tokens": prompt_tokens,
        "completion_tokens": completion_tokens,
        "total_tokens": total_tokens,
        "response_time": response_time,
        "cost": cost,
        "timestamp": timestamp or datetime.now(timezone.utc),
    }


def build_feedback_record(
    conversation_id: int | None,
    source: str,
    relevance: str | None = None,
    explanation: str | None = None,
    score: int | None = None,
    timestamp: datetime | None = None,
) -> dict:
    return {
        "conversation_id": conversation_id,
        "source": source,
        "relevance": relevance,
        "explanation": explanation,
        "score": score,
        "timestamp": timestamp or datetime.now(timezone.utc),
    }


def insert_conversation(conn, record: dict) -> int:
    sql = """
    INSERT INTO conversations (
        question,
        answer,
        model,
        instructions,
        prompt,
        prompt_tokens,
        completion_tokens,
        total_tokens,
        response_time,
        cost,
        timestamp
    ) VALUES (
        :question,
        :answer,
        :model,
        :instructions,
        :prompt,
        :prompt_tokens,
        :completion_tokens,
        :total_tokens,
        :response_time,
        :cost,
        :timestamp
    ) RETURNING id
    """

    result = conn.execute(text(sql), record)
    row = result.fetchone()
    return int(row[0])


def insert_feedback(conn, record: dict) -> None:
    sql = """
    INSERT INTO feedbacks (
        conversation_id,
        source,
        relevance,
        explanation,
        score,
        timestamp
    ) VALUES (
        :conversation_id,
        :source,
        :relevance,
        :explanation,
        :score,
        :timestamp
    )
    """

    conn.execute(text(sql), record)

