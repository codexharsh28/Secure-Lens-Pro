# Firebase setup

1. Create or select a Firebase project owned by the team.
2. Enable Email/Password in Authentication.
3. Create a Cloud Firestore database.
4. Register the Flutter Android and Web apps. Download the Android google-services.json into flutter_app/android/app/. For web, provide the app's API key, app ID, sender ID, project ID, and auth domain through the FIREBASE_WEB_API_KEY, FIREBASE_WEB_APP_ID, FIREBASE_MESSAGING_SENDER_ID, FIREBASE_PROJECT_ID, and FIREBASE_AUTH_DOMAIN Dart defines.
5. Create a service account for the Flask backend with only the Firebase/Firestore access the app requires. Put its project ID, client email, and private key in backend environment variables. Never add a service account JSON or private key to Git.
6. Deploy the checked-in Firestore rules using the Firebase CLI: firebase deploy --only firestore:rules.
7. Create an account through the app. To grant admin access, update that user's Firestore document in the Firebase Console and set role to admin. Do not use a default or shared admin password.

The client API key in Firebase options identifies the Firebase app and is not a service-account secret. Restrict its use using Firebase/Google Cloud settings as appropriate, and rely on Authentication plus Firestore rules for access control.
