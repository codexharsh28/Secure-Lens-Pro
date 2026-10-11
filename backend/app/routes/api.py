from functools import wraps

from flask import Blueprint, g, jsonify, request

from app.services.breach_service import lookup_breach
from app.services.cyber_score import calculate_cyber_score
from app.services.dashboard_service import get_admin_metrics, get_admin_users
from app.services.firebase_service import (
    get_user_role,
    save_assistant_activity,
    save_scan_result,
    verify_id_token,
)
from app.services.gemini_service import GeminiService
from app.services.hugging_face_service import HuggingFaceService

api_blueprint = Blueprint("api", __name__)
hf_service = HuggingFaceService()
gemini_service = GeminiService()


def _json_payload() -> dict:
    payload = request.get_json(silent=True)
    return payload if isinstance(payload, dict) else {}


def authenticated(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        authorization = request.headers.get("Authorization", "")
        scheme, _, token = authorization.partition(" ")
        if scheme.lower() != "bearer" or not token.strip():
            return jsonify({"error": "Authentication required."}), 401
        try:
            claims = verify_id_token(token.strip())
        except Exception:
            return jsonify({"error": "Authentication token is invalid or expired."}), 401
        g.user_id = str(claims.get("uid", ""))
        if not g.user_id:
            return jsonify({"error": "Authentication token has no user identity."}), 401
        return view(*args, **kwargs)

    return wrapped


def admin_only(view):
    @wraps(view)
    @authenticated
    def wrapped(*args, **kwargs):
        try:
            role = get_user_role(g.user_id)
        except Exception:
            return jsonify({"error": "Admin access could not be verified."}), 503
        if role != "admin":
            return jsonify({"error": "Admin access required."}), 403
        return view(*args, **kwargs)

    return wrapped


@api_blueprint.get("/health")
def health_check():
    return jsonify({"status": "ok", "service": "secure-lens-backend"})


@api_blueprint.post("/scan/email")
@authenticated
def scan_email():
    payload = _json_payload()
    content = payload.get("content")
    if not isinstance(content, str) or not content.strip() or len(content) > 10000:
        return jsonify({"error": "Message content must be between 1 and 10000 characters."}), 400
    content = content.strip()

    result = hf_service.analyze_email(content)
    save_scan_result("email", result, user_id=g.user_id)
    return jsonify({"type": "email", "content_length": len(content), **result})


@api_blueprint.post("/scan/url")
@authenticated
def scan_url():
    payload = _json_payload()
    url = payload.get("url")
    if not isinstance(url, str) or not url.strip() or len(url) > 2048:
        return jsonify({"error": "URL must be between 1 and 2048 characters."}), 400
    url = url.strip()

    result = hf_service.analyze_url(url)
    save_scan_result("url", result, user_id=g.user_id)
    return jsonify({"type": "url", "url": url, **result})


@api_blueprint.post("/breach/check")
@authenticated
def breach_check():
    payload = _json_payload()
    identifier = payload.get("identifier", "")
    if not isinstance(identifier, str):
        return jsonify({"error": "Email address must be text."}), 400
    identifier = identifier.strip()
    if len(identifier) > 254:
        return jsonify({"error": "Email address is too long."}), 400

    result = lookup_breach(identifier)
    save_scan_result(
        "breach",
        {
            "risk_level": "high" if result.get("exposed") else "low",
            "summary": result.get("message", ""),
            **result,
        },
        user_id=g.user_id,
    )
    return jsonify(result)


@api_blueprint.post("/chat")
@authenticated
def chat():
    payload = _json_payload()
    message = payload.get("message")
    if not isinstance(message, str) or not message.strip() or len(message) > 4000:
        return jsonify({"error": "Message must be between 1 and 4000 characters."}), 400
    message = message.strip()

    save_assistant_activity(message, user_id=g.user_id)
    return jsonify(gemini_service.generate_chat_reply(message))


@api_blueprint.post("/score")
@authenticated
def score_user():
    return jsonify(calculate_cyber_score(user_id=g.user_id))


@api_blueprint.get("/admin/metrics")
@admin_only
def admin_metrics():
    return jsonify(get_admin_metrics())


@api_blueprint.get("/admin/users")
@admin_only
def admin_users():
    return jsonify(get_admin_users())
