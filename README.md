# Frontend

A Flutter project for the mobile frontend.

## Getting Started

This project is a starting point for a Flutter application.

### Useful Resources

* [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
* [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
* [Flutter Documentation](https://docs.flutter.dev/)

---

## ⚠️ Security Notice

**Do not commit secrets, API keys, or test card numbers to the repository.**
All environment-specific values should be stored in a local `.env` file and excluded via `.gitignore`.

---

## Environment Configuration

Create a `.env` file at the project root (this file should NOT be committed):

```env
API_URL=http://YOUR_LOCAL_IP:8000/api

FIREBASE_API_KEY=YOUR_FIREBASE_API_KEY

STRIPE_PUBLISHABLE_KEY=YOUR_STRIPE_PUBLISHABLE_KEY
STRIPE_MERCHANT_ID=com.example.frontend

GOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com
GOOGLE_WEB_CLIENT_ID=YOUR_GOOGLE_WEB_CLIENT_ID
GOOGLE_WEB_REDIRECT_URI=https://your-project.firebaseapp.com/__/auth/handler
```

### `.env.example` (Commit this file)

```env
API_URL=
STORAGE_URL=
FIREBASE_API_KEY=
STRIPE_PUBLISHABLE_KEY=
STRIPE_MERCHANT_ID=
GOOGLE_CLIENT_ID=
GOOGLE_WEB_CLIENT_ID=
GOOGLE_WEB_REDIRECT_URI=
```

---

## Running the Project

```bash
flutter pub get
flutter run
```

---

## Notes

* Use **test card numbers only in Stripe test mode** and never store them in source control.
* Update `API_URL` and `STORAGE_URL` when switching between local, staging, and production environments.
* For production builds, use secure CI/CD secrets or platform-specific secret managers.
