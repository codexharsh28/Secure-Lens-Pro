# Architecture

## Components

- Flutter client: Firebase Authentication, user interface, and API requests.
- Flask API: verifies Firebase ID tokens, runs scans and scoring, and calls AI providers.
- Firebase Authentication: manages user identities and email verification.
- Cloud Firestore: stores user profiles and backend-owned scan/activity records.
- Gemini: cybersecurity chat and primary message/URL analysis.
- Hugging Face: optional fallback message classification. URL fallback uses local heuristics.

## Trust boundaries

The Flutter client sends the signed-in user's Firebase ID token as a Bearer token. Flask verifies the token and uses its UID as the owner for saved records; it ignores client-provided user IDs. Admin endpoints additionally read the caller's role from their Firestore profile.

Firestore client rules permit access to a user's own profile and prevent the client from changing its role. Scan and assistant records are backend-only. Firebase Admin credentials and AI provider keys stay in backend environment variables.

## Data flow

1. The user signs in through Firebase Authentication.
2. The client requests an ID token and sends it to Flask for protected API calls.
3. Flask verifies the token and takes the identity from the verified token.
4. For a scan, Flask submits the text or link to the configured analyzer, saves the result and timestamp in Firestore, and returns an explanation.
5. The score summarizes recent scan records. It is a lightweight prototype indicator, not a security certification.

## Known limits

The breach feature is a labelled demo dataset, not a breach intelligence integration. AI results are probabilistic. Submitted content may be sent to an external model provider. The in-memory OTP service has been removed; account verification uses Firebase email verification.
