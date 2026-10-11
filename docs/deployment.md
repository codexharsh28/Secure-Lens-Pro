# Deployment checklist

The source is prepared for deployment but does not currently point to a live backend or Firebase project.

## Backend

1. Create a web service with the repository root directory set to backend.
2. Install dependencies from requirements.txt; start the service with the checked-in Procfile.
3. Add the variables in backend/.env.example through the host's private environment settings.
4. Set CORS_ORIGINS to the exact public Flutter Web origin. Do not leave it as * for a public deployment.
5. Confirm the service's /api/health endpoint responds over HTTPS.

## Firebase

Use a Firebase project owned by the team. Enable Email/Password Authentication, create Firestore, deploy firestore.rules, register the Android package com.codexharsh28.securelenspro, and register the web app. Configure a backend service account with Firestore access and put its credentials only in the backend host's secret settings.

## Flutter Web

Build with the deployed HTTPS API URL and the Firebase Web app values:

~~~
flutter build web --release \
  --dart-define=API_BASE_URL=https://YOUR-BACKEND-HOST/api \
  --dart-define=FIREBASE_WEB_API_KEY=YOUR_WEB_API_KEY \
  --dart-define=FIREBASE_WEB_APP_ID=YOUR_WEB_APP_ID \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID \
  --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID \
  --dart-define=FIREBASE_AUTH_DOMAIN=YOUR_PROJECT_ID.firebaseapp.com
~~~

Host the generated build/web directory as a static site and add that site's exact origin to the backend's CORS_ORIGINS.

## Android

Download google-services.json for the registered Android package to flutter_app/android/app/. Build a release APK/AAB with API_BASE_URL pointing to the backend's HTTPS URL. Never use a localhost API URL for a distributed release.

No deployment can be completed until the team creates/chooses the Firebase project and hosting accounts and supplies their configuration values.
