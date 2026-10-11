import hashlib
import re


# This small list is used only to make a predictable hackathon demo. It is not
# connected to a breach database and every response is marked as simulated.
DEMO_BREACH_LIBRARY = [
    {"name": "LinkedIn", "year": 2021, "data_types": ["Email address", "Full name"]},
    {"name": "Dropbox", "year": 2020, "data_types": ["Email address", "Password hint"]},
    {"name": "Canva", "year": 2019, "data_types": ["Email address", "Username"]},
    {"name": "Adobe", "year": 2018, "data_types": ["Email address", "Username"]},
    {"name": "Twitter", "year": 2022, "data_types": ["Email address", "Phone number"]},
    {"name": "MyFitnessPal", "year": 2019, "data_types": ["Email address", "Username"]},
]

_EMAIL_RE = re.compile(r"^[^\s@]+@[^\s@]+\.[^\s@]+$")


def _result(identifier: str, exposed: bool, breaches: list[dict], message: str, recommendation: str) -> dict:
    return {
        "identifier": identifier,
        "exposed": exposed,
        "breach_count": len(breaches),
        "breaches": breaches,
        "message": message,
        "recommendation": recommendation,
        "is_simulated": True,
        "data_source": "Secure Lens demo dataset (simulated)",
    }


def lookup_breach(identifier: str) -> dict:
    identifier = (identifier or "").strip().lower()
    recommendation = (
        "Use a unique password for every account, enable two-factor authentication, "
        "and review recent account activity."
    )

    if not _EMAIL_RE.fullmatch(identifier):
        return _result(
            identifier,
            False,
            [],
            "Enter a valid email address. This demo does not query real breach databases.",
            recommendation,
        )

    digest = hashlib.sha256(identifier.encode("utf-8")).hexdigest()
    score = int(digest[:8], 16) % 100
    if score < 35:
        return _result(
            identifier,
            False,
            [],
            "Demo result: no sample record was selected. This is not a real breach lookup.",
            recommendation,
        )

    breach_count = 1 + (score >= 75) + (score >= 92)
    start = int(digest[8:16], 16) % len(DEMO_BREACH_LIBRARY)
    breaches = [
        DEMO_BREACH_LIBRARY[(start + offset) % len(DEMO_BREACH_LIBRARY)]
        for offset in range(breach_count)
    ]
    names = ", ".join(item["name"] for item in breaches)
    return _result(
        identifier,
        True,
        breaches,
        f"Demo result only: sample breach entries ({names}) were selected for this presentation. "
        "This does not mean this email was found in those breaches.",
        recommendation,
    )
