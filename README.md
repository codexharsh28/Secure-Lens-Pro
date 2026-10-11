# Secure Lens Pro

Secure Lens Pro is a Srijan 2K26 college hackathon prototype for AI-assisted phishing awareness. It helps a signed-in user review a suspicious message or URL, understand the risk indicators, and get practical safety guidance.

## Hackathon demo scope

- Firebase sign-in and per-user activity.
- Message and URL risk analysis using Gemini, with Hugging Face/rule-based fallbacks.
- A cybersecurity assistant.
- A clearly labelled **simulated** breach demonstration. It does not query a real breach database.
- A simple activity-based cyber score and an admin dashboard.

This is an awareness prototype, not antivirus software or continuous device protection. AI findings can be wrong; users should verify suspicious requests independently.

## Project layout

- flutter_app/ — Flutter Android and web clients.
- backend/ — Flask API and AI/Firebase integrations.
- firestore.rules — Firebase client access rules.
- docs/ — setup and API notes.

## Run locally

### 1. Configure Firebase

Create or select a Firebase project, enable Email/Password Authentication, and create a Firestore database. Register the Flutter Android app using package ID com.codexharsh28.securelenspro and register the Web app. For Android, download that project's google-services.json to flutter_app/android/app/google-services.json. For web, supply the Firebase web app values as FIREBASE_WEB_API_KEY, FIREBASE_WEB_APP_ID, FIREBASE_MESSAGING_SENDER_ID, FIREBASE_PROJECT_ID, and FIREBASE_AUTH_DOMAIN Dart defines.

Deploy the included rules with the Firebase CLI using firebase deploy --only firestore:rules. Create user accounts through the app. To grant admin access, change that user's role field to admin in the Firebase Console; never ship a shared administrator password.

### 2. Configure and run the backend

~~~
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
python run.py
~~~

Fill in backend/.env with a Firebase service-account identity and the Gemini/Hugging Face keys you intend to use. Keep .env private. Firebase service-account keys and AI provider keys belong on the server only. Signup verification uses Firebase Authentication; no SMTP account is required.

The Flask development API listens on port 5000. Use http://127.0.0.1:5000/api for Flutter Web on the same computer or http://10.0.2.2:5000/api for the Android emulator, or provide another API URL at Flutter build/run time.

### 3. Run the Flutter client

~~~
cd flutter_app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
~~~

For Flutter web on the same computer, use --dart-define=API_BASE_URL=http://127.0.0.1:5000/api and the five Firebase web Dart defines listed above. For a hosted build, set API_BASE_URL to the HTTPS URL of the deployed backend.

## Backend environment

See backend/.env.example. Set CORS_ORIGINS to the exact web client origins in deployment. Mobile clients generally do not send a browser Origin header. The backend verifies Firebase ID tokens for user features and checks the Firestore role for admin routes.

## Deployment outline

The Flask API can run under Gunicorn using the included backend/Procfile; configure the hosting provider's root directory as backend and add the environment values from .env.example in its secret/environment settings. Deploy Firestore rules separately. Build and host Flutter Web or distribute the Android app, and configure its API URL to the backend's HTTPS address.

The repository does not contain a live backend URL or hosting account configuration. A real deployment still needs accounts and project credentials controlled by the team.

## Important limitations

- The breach screen uses a small deterministic demo dataset and labels its results as simulated. It does not establish whether an address was involved in a real breach.
- The cyber score is a simple summary of recent recorded activity, not a validated measure of a person's security.
- Message content is sent to the configured AI provider for analysis. Do not submit real credentials, OTPs, or confidential messages.
- API scans, chat, scores, and admin routes require Firebase authentication. Add per-user and per-IP request limits before public production use.
- Firebase client rules protect profile documents; backend service-account access bypasses Firestore rules.

## License

No license is currently specified. Add one before accepting outside contributions or publishing a reusable package.
