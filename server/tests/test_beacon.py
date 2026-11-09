from fastapi.testclient import TestClient

from app import main
from app.main import DeviceBeacon, build_telegram_message


def sample_beacon() -> DeviceBeacon:
    return DeviceBeacon.model_validate(
        {
            "event_id": "3b12f1df-5232-4804-897e-917bf397618a",
            "sent_at": "2026-11-08T21:00:00Z",
            "app": {"name": "SketchLens", "version": "1.0.0", "build": "4"},
            "device": {
                "platform": "android",
                "manufacturer": "Tecno",
                "brand": "Tecno",
                "model": "KI5k <test>",
                "os_version": "14",
                "api_level": 34,
            },
        }
    )


def test_message_escapes_html_and_contains_device_info() -> None:
    message = build_telegram_message(sample_beacon())
    assert "Tecno" in message
    assert "KI5k &lt;test&gt;" in message
    assert "API 34" in message
    assert "3b12f1df" not in message


def test_payload_rejects_unrequested_fields() -> None:
    payload = sample_beacon().model_dump()
    payload["device"]["imei"] = "should-not-be-accepted"
    try:
        DeviceBeacon.model_validate(payload)
    except ValueError:
        pass
    else:
        raise AssertionError("Unexpected device fields must be rejected")


def test_relay_sends_once_and_deduplicates(monkeypatch, tmp_path) -> None:
    monkeypatch.setattr(main, "DATABASE", tmp_path / "beacons.sqlite3")
    monkeypatch.setenv("TELEGRAM_BOT_TOKEN", "test-token")
    monkeypatch.setenv("TELEGRAM_CHAT_ID", "123456")
    telegram_calls = []

    class Response:
        def raise_for_status(self) -> None:
            return None

        @staticmethod
        def json() -> dict[str, bool]:
            return {"ok": True}

    class FakeAsyncClient:
        def __init__(self, **kwargs) -> None:
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *args) -> None:
            return None

        async def post(self, url: str, *, json: dict):
            telegram_calls.append((url, json))
            return Response()

    monkeypatch.setattr(main.httpx, "AsyncClient", FakeAsyncClient)
    payload = sample_beacon().model_dump()
    with TestClient(main.app) as client:
        first = client.post("/api/v1/beacon", json=payload)
        duplicate = client.post("/api/v1/beacon", json=payload)

    assert first.status_code == 200
    assert first.json() == {"accepted": True, "duplicate": False}
    assert duplicate.status_code == 200
    assert duplicate.json() == {"accepted": True, "duplicate": True}
    assert len(telegram_calls) == 1
    assert telegram_calls[0][1]["chat_id"] == "123456"
