import logging
import os
import time
from datetime import datetime, timezone

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Dict
from pydantic import BaseModel, Field, field_validator
from sqlalchemy import text

from app.agent import agent
from app.calculate_cost import calculate_cost
from app.database import (
    engine,
    initialize_database,
    build_conversation_record,
    build_feedback_record,
    insert_conversation,
    insert_feedback,
)

from contextlib import asynccontextmanager

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s"
)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting HealthSecure API")

    try:
        initialize_database()
        logger.info("Database initialization completed successfully")
    except Exception:
        logger.exception("Database initialization failed")
        raise
    yield
    logger.info("Shutting down HealthSecure API")


app = FastAPI(
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class QuestionRequest(BaseModel):
    message: str = Field(..., min_length=1)
    history: List[Dict] = Field(default_factory=list)

    @field_validator("message")
    @classmethod
    def validate_message(cls, value):

        value = value.strip()

        if not value:
            raise ValueError("Message cannot be empty")

        return value

class FeedbackRequest(BaseModel):
    question: str
    response: str
    rating: str
    conversation_id: int | None = None
    source: str = "ui"
    relevance: str | None = None
    explanation: str | None = None
    score: int | None = None

@app.get("/api/healthcheck")
def health():
    logger.debug("Healthcheck endpoint called")

    return {
        "status": "ok"
    }

@app.post("/api/question")
def chat(request: QuestionRequest):
    logger.info(
        "Received question request. History length: %s",
        len(request.history)
    )

    try:

        messages = []

        for item in request.history:
            messages.append(
                (
                    item["role"],
                    item["content"]
                )
            )

        messages.append(
            (
                "user",
                request.message
            )
        )

        logger.info(
            "Starting agent execution"
        )

        health_agent = agent()

        started_at = time.perf_counter()
        response = health_agent.invoke(
            {
                "messages": messages
            }
        )
        response_time = round(time.perf_counter() - started_at, 6)

        logger.info(
            "Agent execution completed successfully"
        )

        input_tokens = response["messages"][-1].usage_metadata.get(
            "input_tokens",
            0
        )

        output_tokens = response["messages"][-1].usage_metadata.get(
            "output_tokens",
            0
        )
        total_tokens = input_tokens + output_tokens

        cost = calculate_cost(
            input_tokens,
            output_tokens
        )

        answer = response["messages"][-1].content
        instructions = response["messages"][-1].response_metadata.get(
            "model_name",
            ""
        )
        prompt = str(messages)

        conversation_record = build_conversation_record(
            question=request.message,
            answer=answer,
            model=os.getenv("OPENAI_CHAT_MODEL", "gpt-4.1-mini"),
            instructions=instructions,
            prompt=prompt,
            prompt_tokens=input_tokens,
            completion_tokens=output_tokens,
            total_tokens=total_tokens,
            response_time=response_time,
            cost=cost,
            timestamp=datetime.now(timezone.utc),
        )

        with engine.begin() as conn:
            conversation_id = insert_conversation(conn, conversation_record)

        logger.info(
            "Request completed. Input tokens: %s, Output tokens: %s, Cost: %.6f, Response time: %.6f, Conversation id: %s",
            input_tokens,
            output_tokens,
            cost,
            response_time,
            conversation_id,
        )

        return {
            "response": answer,
            "cost": cost,
            "conversation_id": conversation_id,
        }

    except Exception:
        logger.exception(
            "Error occurred while processing question request"
        )

        raise HTTPException(
            status_code=500,
            detail="Unable to process request at this time"
        )

@app.post("/api/feedback")
def save_feedback(feedback: FeedbackRequest):
    logger.info(
        "Received feedback submission. Rating: %s",
        feedback.rating
    )

    try:
        with engine.begin() as conn:
            feedback_record = build_feedback_record(
                conversation_id=feedback.conversation_id,
                source=feedback.source,
                relevance=feedback.relevance,
                explanation=feedback.explanation,
                score=feedback.score,
                timestamp=datetime.now(timezone.utc),
            )

            insert_feedback(conn, feedback_record)

        logger.info(
            "Feedback saved successfully"
        )

        return {
            "message": "Feedback saved successfully"
        }

    except Exception:
        logger.exception(
            "Failed to save feedback"
        )

        raise HTTPException(
            status_code=500,
            detail="Unable to save feedback"
        )


@app.get("/api/monitoring")
def monitoring(limit: int = 20):
    logger.info("Fetching recent monitoring data with limit=%s", limit)

    sql = """
    SELECT
        c.id,
        c.question,
        c.answer,
        c.model,
        c.prompt_tokens,
        c.completion_tokens,
        c.total_tokens,
        c.response_time,
        c.cost,
        c.timestamp,
        f.id AS feedback_id,
        f.source,
        f.relevance,
        f.explanation,
        f.score,
        f.timestamp AS feedback_timestamp
    FROM conversations c
    LEFT JOIN feedbacks f ON f.conversation_id = c.id
    ORDER BY c.timestamp DESC, f.id DESC
    LIMIT :limit
    """

    try:
        with engine.begin() as conn:
            rows = conn.execute(text(sql), {"limit": limit}).mappings().all()

        return {
            "count": len(rows),
            "items": [dict(row) for row in rows],
        }
    except Exception:
        logger.exception("Failed to fetch monitoring data")
        raise HTTPException(
            status_code=500,
            detail="Unable to fetch monitoring data"
        )