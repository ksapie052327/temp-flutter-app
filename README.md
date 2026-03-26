# KSAPIE 🔐

Private encrypted messenger.

## Stack
- Flutter 3.22.3
- AGP 8.2.1
- Gradle 8.2
- Kotlin 1.9.22
- Java 11
- Firebase BoM 32.7.0

## Setup

### 1. Firebase
1. Go to console.firebase.google.com
2. Create project → `ksapie`
3. Add Android app → package: `com.ksapie.ksapie`
4. Download `google-services.json`
5. Place in `android/app/google-services.json`
6. Enable: Authentication (Email/Password) + Firestore

### 2. Firestore Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isLoggedIn() { return request.auth != null; }
    match /users/{userId} {
      allow read, write: if isLoggedIn() && request.auth.uid == userId;
    }
    match /chats/{chatId} {
      allow read: if isLoggedIn() && request.auth.uid in resource.data.participants;
      allow create: if isLoggedIn() && request.auth.uid in request.resource.data.participants;
      allow update: if isLoggedIn() && request.auth.uid in resource.data.participants;
      allow delete: if false;
      match /messages/{messageId} {
        allow read: if isLoggedIn() && request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
        allow create: if isLoggedIn() && request.resource.data.senderId == request.auth.uid;
        allow update, delete: if isLoggedIn() && resource.data.senderId == request.auth.uid;
      }
    }
  }
}
```

### 3. Build
Push to GitHub → Actions tab → Download APK artifact
