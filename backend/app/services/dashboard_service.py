from __future__ import annotations

from datetime import datetime, timedelta, timezone

from app.services.cyber_score import calculate_cyber_score
from app.services.firebase_service import get_firestore_client

DANGER_LEVELS = {"high", "critical", "phishing", "danger"}


def get_admin_metrics() -> dict:
    try:
        db = get_firestore_client()
        user_snapshots = list(db.collection("users").stream())
        scan_docs = [doc.to_dict() or {} for doc in db.collection("scan_results").stream()]
    except Exception as error:
        print(f"Failed to load admin metrics: {error}")
        return {
            "total_users": 0,
            "high_risk_users": 0,
            "recent_threats": 0,
            "average_cyber_score": 0,
        }

    user_entries = []
    for snapshot in user_snapshots:
        data = snapshot.to_dict() or {}
        if str(data.get("role", "user")).lower() == "admin":
            continue

        score_result = calculate_cyber_score(user_id=snapshot.id)
        score = int(score_result.get("cyber_score", 0))
        has_activity = bool(score_result.get("has_activity"))
        risk_level = _risk_from_score(score) if has_activity else "unknown"

        user_entries.append(
            {
                "id": snapshot.id,
                "score": score,
                "risk_level": risk_level,
                "has_activity": has_activity,
            }
        )

    total_users = len(user_entries)
    high_risk_users = len(
        [user for user in user_entries if user["risk_level"] == "high"]
    )

    scores = [
        user["score"]
        for user in user_entries
        if user["has_activity"] and user["score"] > 0
    ]
    average_cyber_score = round(sum(scores) / len(scores)) if scores else 0

    recent_threats = 0
    week_ago = datetime.now(timezone.utc) - timedelta(days=7)

    for scan in scan_docs:
        level = str(scan.get("riskLevel") or scan.get("risk_level") or "").lower()
        created_at = scan.get("createdAt") or scan.get("created_at")

        if isinstance(created_at, datetime):
            if created_at.tzinfo is None:
                created_at = created_at.replace(tzinfo=timezone.utc)

            if created_at >= week_ago and level in DANGER_LEVELS:
                recent_threats += 1

    return {
        "total_users": total_users,
        "high_risk_users": high_risk_users,
        "recent_threats": recent_threats,
        "average_cyber_score": average_cyber_score,
    }


def get_admin_users() -> dict:
    try:
        db = get_firestore_client()
        user_snapshots = list(db.collection("users").stream())
    except Exception as error:
        print(f"Failed to load admin users: {error}")
        return {"users": []}

    users = []

    for snapshot in user_snapshots:
        data = snapshot.to_dict() or {}
        role = str(data.get("role", "user")).lower()

        if role == "admin":
            continue

        score_result = calculate_cyber_score(user_id=snapshot.id)
        score = int(score_result.get("cyber_score", 0))
        has_activity = bool(score_result.get("has_activity"))
        risk_level = _risk_from_score(score) if has_activity else "unknown"

        users.append(
            {
                "id": snapshot.id,
                "name": str(data.get("name", "Unnamed User")),
                "email": str(data.get("email", "")),
                "role": role,
                "photo_url": str(data.get("photoUrl", "")),
                "cyber_score": score,
                "has_activity": has_activity,
                "risk_level": risk_level,
                "status_label": _status_label(risk_level),
                "created_at": _format_created_at(data.get("createdAt")),
            }
        )

    users.sort(
        key=lambda item: (
            _risk_priority(item["risk_level"]),
            item["name"].lower(),
        )
    )

    return {"users": users}


def _risk_from_score(score: int) -> str:
    if score >= 80:
        return "low"
    if score >= 60:
        return "medium"
    return "high"


def _status_label(risk_level: str) -> str:
    if risk_level == "unknown":
        return "No activity yet"
    if risk_level == "high":
        return "Needs Attention"
    if risk_level == "medium":
        return "Monitor"
    return "Stable"


def _risk_priority(risk_level: str) -> int:
    if risk_level == "high":
        return 0
    if risk_level == "medium":
        return 1
    if risk_level == "low":
        return 2
    return 3


def _format_created_at(value) -> str:
    if isinstance(value, datetime):
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc).strftime("%d %b %Y")

    return "Not available"
