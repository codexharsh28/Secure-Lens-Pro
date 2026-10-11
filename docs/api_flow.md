# API flow

Base path: /api

## Public endpoint

| Method | Path | Purpose |
| --- | --- | --- |
| GET | /health | Backend status |

## Firebase-authenticated endpoints

Send Authorization: Bearer <Firebase ID token> with each request. The backend derives the user ID from the verified token; do not send or trust a user ID in the request body.

| Method | Path | Purpose |
| --- | --- | --- |
| POST | /scan/email | Analyze message or email text |
| POST | /scan/url | Analyze a URL |
| POST | /breach/check | Run the clearly simulated breach demo |
| POST | /chat | Ask the cybersecurity assistant |
| POST | /score | Calculate the signed-in user's activity score |

Admin-only endpoints also require a verified token and a role: admin field on that user's Firestore profile:

| Method | Path | Purpose |
| --- | --- | --- |
| GET | /admin/metrics | Aggregate user and threat metrics |
| GET | /admin/users | User list and score summaries |

The API accepts JSON request bodies. Message content is capped at 10,000 characters, URLs at 2,048 characters, and assistant prompts at 4,000 characters.
