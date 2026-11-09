"""Small Telegram relay for opt-in SketchLens device beacons."""

from __future__ import annotations

import html
import os
import sqlite3
import time
from contextlib import asynccontextmanager
from pathlib import Path

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel, ConfigDict, Field

SERVER_DIR = Path(__file__).resolve().parents[1]
load_dotenv(SERVER_DIR / ".env", override=False)

DATABASE = Path(os.getenv("BEACON_DB_PATH", "beacons.sqlite3"))
if not DATABASE.is_absolute():
    DATABASE = SERVER_DIR / DATABASE
MAX_PER_MINUTE = 10
_request_times: dict[str, list[float]] = {}


class AppInfo(BaseModel):
    model_config = ConfigDict(extra="forbid")
    name: str = Field(max_length=80)
    version: str = Field(max_length=40)
    build: str = Field(max_length=40)


class DeviceInfo(BaseModel):
    model_config = ConfigDict(extra="forbid")
    platform: str = Field(max_length=20)
    manufacturer: str | None = Field(default=None, max_length=80)
    brand: str | None = Field(default=None, max_length=80)
    model: str | None = Field(default=None, max_length=120)
    os_version: str | None = Field(default=None, max_length=80)
    api_level: int | None = Field(default=None, ge=1, le=999)


class DeviceBeacon(BaseModel):
    model_config = ConfigDict(extra="forbid")
    event_id: str = Field(min_length=36, max_length=36, pattern=r"^[0-9a-fA-F-]+$")
    sent_at: str = Field(max_length=40)
    app: AppInfo
    device: DeviceInfo


def build_telegram_message(beacon: DeviceBeacon) -> str:
    """Format only the explicitly collected, allow-listed device fields."""
    device = beacon.device
    lines = [
        "<b>SketchLens device beacon</b>",
        f"Device: {html.escape(device.manufacturer or '')} "
        f"{html.escape(device.brand or '')} {html.escape(device.model or 'Unknown')}",
        f"Platform: {html.escape(device.platform)} "
        f"{html.escape(device.os_version or '')}"
        + (f" (API {device.api_level})" if device.api_level is not None else ""),
        f"App: {html.escape(beacon.app.name)} "
        f"{html.escape(beacon.app.version)} ({html.escape(beacon.app.build)})",
        f"Queued at: {html.escape(beacon.sent_at)}",
    ]
    return "\n".join(lines)[:4000]


def _initialize_db() -> None:
    DATABASE.parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(DATABASE) as connection:
        connection.execute(
            "CREATE TABLE IF NOT EXISTS delivered_beacons "
            "(event_id TEXT PRIMARY KEY, delivered_at TEXT NOT NULL)"
        )


@asynccontextmanager
async def lifespan(_: FastAPI):
    _initialize_db()
    yield


app = FastAPI(title="SketchLens Beacon Relay", lifespan=lifespan)


@app.get("/healthz")
async def healthz() -> dict[str, str]:
    return {
        "status": "ok",
        "telegram": "configured"
        if os.getenv("TELEGRAM_BOT_TOKEN", "").strip()
        and os.getenv("TELEGRAM_CHAT_ID", "").strip()
        else "not_configured",
    }


@app.post("/api/v1/beacon")
async def receive_beacon(beacon: DeviceBeacon, request: Request) -> dict[str, bool]:
    now = time.monotonic()
    client = request.client.host if request.client else "unknown"
    recent = [stamp for stamp in _request_times.get(client, []) if now - stamp < 60]
    if len(recent) >= MAX_PER_MINUTE:
        raise HTTPException(status_code=429, detail="Beacon rate limit exceeded")
    recent.append(now)
    _request_times[client] = recent

    token = os.getenv("TELEGRAM_BOT_TOKEN", "").strip()
    chat_id = os.getenv("TELEGRAM_CHAT_ID", "").strip()
    if not token or not chat_id:
        raise HTTPException(status_code=503, detail="Telegram relay is not configured")

    with sqlite3.connect(DATABASE) as connection:
        delivered = connection.execute(
            "SELECT 1 FROM delivered_beacons WHERE event_id = ?", (beacon.event_id,)
        ).fetchone()
    if delivered:
        return {"accepted": True, "duplicate": True}

    url = f"https://api.telegram.org/bot{token}/sendMessage"
    try:
        async with httpx.AsyncClient(timeout=10) as client_session:
            response = await client_session.post(
                url,
                json={
                    "chat_id": chat_id,
                    "text": build_telegram_message(beacon),
                    "parse_mode": "HTML",
                    "disable_web_page_preview": True,
                },
            )
            response.raise_for_status()
            result = response.json()
            if not result.get("ok"):
                raise RuntimeError("Telegram rejected the beacon")
    except (httpx.HTTPError, RuntimeError, ValueError) as error:
        raise HTTPException(status_code=502, detail="Telegram delivery failed") from error

    with sqlite3.connect(DATABASE) as connection:
        connection.execute(
            "INSERT OR IGNORE INTO delivered_beacons(event_id, delivered_at) "
            "VALUES (?, datetime('now'))",
            (beacon.event_id,),
        )
    return {"accepted": True, "duplicate": False}
