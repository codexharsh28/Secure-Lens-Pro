from __future__ import annotations

from datetime import datetime, timedelta, timezone

from app.services.firebase_service import get_firestore_client, update_user_score

DANGER_LEVELS = {"high", "critical", "phishing", "danger"}
WARNING_LEVELS = {"warning", "medium", "suspicious"}


def calculate_cyber_score(
    user_id: str | None = None,
    signals: dict | None = None,
) -> dict:
    try:
        db = get_firestore_client()
        scan_docs = [doc.to_dict() or {} for doc in db.collection("scan_results").stream()]
        chat_docs = [doc.to_dict() or {} for doc in db.collection("assistant_activity").stream()]
        result = _calculate_live_score(scan_docs, chat_docs, user_id=user_id)

        if user_id:
            update_user_score(
                user_id=user_id,
                cyber_score=int(result["cyber_score"]),
                level=str(result["level"]),
                risk_level=_risk_band(int(result["cyber_score"])),
            )

        return result
    except Exception as error:
        print(f"Falling back to signal-based cyber score: {error}")
        return _calculate_fallback_score(signals or {})


def _calculate_live_score(
    scan_docs: list[dict],
    chat_docs: list[dict],
    user_id: str | None = None,
) -> dict:
    now = datetime.now(timezone.utc)
    month_ago = now - timedelta(days=30)

    recent_scans = []
    for scan in scan_docs:
        if user_id and str(scan.get("userId", "")).strip() != user_id:
            continue

        created_at = scan.get("createdAt") or scan.get("created_at")
        if isinstance(created_at, datetime):
            if created_at.tzinfo is None:
                created_at = created_at.replace(tzinfo=timezone.utc)
            if created_at >= month_ago:
                recent_scans.append(scan)

    recent_chats = 0
    for item in chat_docs:
        if user_id and str(item.get("userId", "")).strip() != user_id:
            continue

        created_at = item.get("createdAt") or item.get("created_at")
        if isinstance(created_at, datetime):
            if created_at.tzinfo is None:
                created_at = created_at.replace(tzinfo=timezone.utc)
            if created_at >= month_ago:
                recent_chats += 1

    high_risk_events = 0
    medium_risk_events = 0
    safe_events = 0
    breach_hits = 0

    for scan in recent_scans:
        level = str(scan.get("riskLevel") or scan.get("risk_level") or "").lower()
        scan_type = str(scan.get("scanType") or scan.get("scan_type") or "").lower()
        raw_result = scan.get("raw")
        if scan_type == "breach" and isinstance(raw_result, dict) and raw_result.get("is_simulated"):
            continue

        if level in DANGER_LEVELS:
            high_risk_events += 1
            if scan_type == "breach":
                breach_hits += 1
        elif level in WARNING_LEVELS:
            medium_risk_events += 1
        else:
            safe_events += 1

    score = 100
    score -= high_risk_events * 12
    score -= medium_risk_events * 5
    score -= breach_hits * 8

    final_score = max(0, min(100, round(score)))
    level = _score_level(final_score)

    return {
        "cyber_score": final_score,
        "level": level,
        "has_activity": bool(high_risk_events or medium_risk_events or safe_events),
        "factors": {
            "high_risk_events": high_risk_events,
            "medium_risk_events": medium_risk_events,
            "safe_events": safe_events,
            "assistant_usage": recent_chats,
            "breach_hits": breach_hits,
            "user_id": user_id or "",
        },
    }


def _calculate_fallback_score(signals: dict) -> dict:
    password_strength = int(signals.get("password_strength", 70))
    training_completion = int(signals.get("training_completion", 50))
    breach_count = int(signals.get("breach_count", 0))
    risky_clicks = int(signals.get("risky_clicks", 0))

    score = (
        (password_strength * 0.35)
        + (training_completion * 0.30)
        + (max(0, 100 - (breach_count * 15)) * 0.20)
        + (max(0, 100 - (risky_clicks * 20)) * 0.15)
    )

    final_score = max(0, min(100, round(score)))
    level = _score_level(final_score)

    return {
        "cyber_score": final_score,
        "level": level,
        "has_activity": bool(signals),
        "factors": {
            "password_strength": password_strength,
            "training_completion": training_completion,
            "breach_count": breach_count,
            "risky_clicks": risky_clicks,
        },
    }


def _score_level(score: int) -> str:
    if score >= 80:
        return "strong"
    if score >= 60:
        return "moderate"
    return "high-risk"


def _risk_band(score: int) -> str:
    if score >= 80:
        return "low"
    if score >= 60:
        return "medium"
    return "high"
