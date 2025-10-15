# CI/CD Workflow Overview

This document provides a visual overview of the complete CI/CD pipeline for the Note App.

## Workflow Triggers

```
┌─────────────────────────────────────────────────────────┐
│                    GitHub Repository                     │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Push to 'main' or 'develop'  ──┐                      │
│                                  │                       │
│  Pull Request to 'main'      ────┼──►  Trigger Workflow │
│                                  │                       │
└──────────────────────────────────┘                       │
                                                           ▼
```

## Pipeline Stages

### Stage 1: Test (Runs on ALL branches)

```
┌─────────────────────────────────────────────────────────┐
│                     TEST JOB                             │
│                   (Ubuntu Latest)                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. Checkout Code                                       │
│  2. Setup Flutter 3.35.2                                │
│  3. Install Dependencies (flutter pub get)              │
│  4. Verify Formatting (dart format)                     │
│  5. Analyze Code (flutter analyze --fatal-infos)        │
│  6. Run Tests (flutter test)                            │
│                                                          │
│  ✅ PASS ──────────────────────► Continue to Build      │
│  ❌ FAIL ──────────────────────► Stop Pipeline          │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Stage 2: Build & Deploy (Only on 'main' branch)

```
                     ┌──────────────┐
                     │   All Jobs   │
                     │  Run in      │
                     │  Parallel    │
                     └──────┬───────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌───────────────┐   ┌──────────────┐   ┌──────────────┐
│    ANDROID    │   │     iOS      │   │    macOS     │
│  (Ubuntu)     │   │  (macOS)     │   │  (macOS)     │
└───────────────┘   └──────────────┘   └──────────────┘
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐   ┌──────────────┐   ┌──────────────┐
│   WINDOWS     │
│  (Windows)    │
└───────────────┘
```

## Detailed Build Flow

### Android Build Job

```
┌─────────────────────────────────────────────────────────┐
│                  ANDROID BUILD JOB                       │
│                   (Ubuntu Latest)                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. Setup Environment                                   │
│     ├── Checkout code                                   │
│     ├── Setup Flutter 3.35.2                            │
│     ├── Setup Ruby 3.2                                  │
│     └── Install Bundler dependencies                    │
│                                                          │
│  2. Build Phase                                         │
│     ├── flutter pub get                                 │
│     ├── flutter build apk --release                     │
│     └── flutter build appbundle --release               │
│                                                          │
│  3. Upload Artifacts                                    │
│     ├── Upload APK to GitHub (30 days)                  │
│     └── Upload AAB to GitHub (30 days)                  │
│                                                          │
│  4. Deploy to Firebase 🔥                               │
│     ├── cd android                                      │
│     ├── bundle exec fastlane deploy_to_firebase         │
│     └── Testers receive email notification              │
│                                                          │
│  ✅ Artifacts Available:                                │
│     • release-apk (APK file)                            │
│     • release-aab (App Bundle)                          │
│     • Firebase App Distribution                         │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### iOS Build Job

```
┌─────────────────────────────────────────────────────────┐
│                   iOS BUILD JOB                          │
│                   (macOS Latest)                         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. Setup Environment                                   │
│     ├── Checkout code                                   │
│     ├── Setup Flutter 3.35.2                            │
│     ├── Setup Ruby 3.2                                  │
│     └── Install Bundler dependencies                    │
│                                                          │
│  2. Build Phase                                         │
│     ├── flutter pub get                                 │
│     └── flutter build ios --release --no-codesign       │
│                                                          │
│  3. Create IPA                                          │
│     ├── Create Payload directory                        │
│     ├── Copy Runner.app to Payload/                     │
│     └── Zip as app-release.ipa                          │
│                                                          │
│  4. Upload Artifacts                                    │
│     └── Upload IPA to GitHub (30 days)                  │
│                                                          │
│  5. Deploy to Firebase 🔥                               │
│     ├── cd ios                                          │
│     ├── bundle exec fastlane deploy_to_firebase         │
│     └── Testers receive email notification              │
│                                                          │
│  ✅ Artifacts Available:                                │
│     • release-ipa (IPA file)                            │
│     • Firebase App Distribution                         │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### macOS Build Job

```
┌─────────────────────────────────────────────────────────┐
│                  macOS BUILD JOB                         │
│                   (macOS Latest)                         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. Setup Environment                                   │
│     ├── Checkout code                                   │
│     └── Setup Flutter 3.35.2                            │
│                                                          │
│  2. Build Phase                                         │
│     ├── flutter pub get                                 │
│     └── flutter build macos --release                   │
│                                                          │
│  3. Package                                             │
│     └── Zip note_app.app bundle                         │
│                                                          │
│  4. Upload Artifacts                                    │
│     └── Upload ZIP to GitHub (30 days)                  │
│                                                          │
│  ✅ Artifacts Available:                                │
│     • release-macos (ZIP file)                          │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Windows Build Job

```
┌─────────────────────────────────────────────────────────┐
│                 WINDOWS BUILD JOB                        │
│                  (Windows Latest)                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. Setup Environment                                   │
│     ├── Checkout code                                   │
│     └── Setup Flutter 3.35.2                            │
│                                                          │
│  2. Build Phase                                         │
│     ├── flutter pub get                                 │
│     └── flutter build windows --release                 │
│                                                          │
│  3. Package                                             │
│     └── Compress all files to ZIP                       │
│                                                          │
│  4. Upload Artifacts                                    │
│     └── Upload ZIP to GitHub (30 days)                  │
│                                                          │
│  ✅ Artifacts Available:                                │
│     • release-windows (ZIP file)                        │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Firebase App Distribution Flow

```
┌─────────────────────────────────────────────────────────┐
│            FIREBASE APP DISTRIBUTION                     │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  GitHub Actions  ──────►  Fastlane  ──────►  Firebase  │
│                           (Ruby)                         │
│                                                          │
│  1. Build completes successfully                        │
│  2. Fastlane reads secrets:                             │
│     • FIREBASE_TOKEN                                    │
│     • FIREBASE_APP_ID_ANDROID / FIREBASE_APP_ID_IOS     │
│  3. Uploads to Firebase App Distribution                │
│  4. Firebase sends email to tester group                │
│  5. Testers install app via Firebase portal/app         │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Complete Flow Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                         Developer                                 │
└───────────────────────────┬──────────────────────────────────────┘
                            │
                            │ git push origin main
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│                      GitHub Repository                            │
│                    (Trigger CI/CD Workflow)                       │
└───────────────────────────┬──────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│                        TEST STAGE                                 │
│              Format → Analyze → Test → ✅ Pass                    │
└───────────────────────────┬──────────────────────────────────────┘
                            │
                            │ (Only on 'main')
                            ▼
        ┌───────────────────┴───────────────────┐
        │                                       │
        ▼                                       ▼
┌──────────────────┐                  ┌──────────────────┐
│  ANDROID BUILD   │                  │   iOS BUILD      │
│  • Build APK/AAB │                  │   • Build IPA    │
│  • Upload GitHub │                  │   • Upload GitHub│
│  • Deploy Firebase│                 │   • Deploy Firebase│
└────────┬─────────┘                  └────────┬─────────┘
         │                                     │
         │            ┌──────────────────┐    │
         │            │   macOS BUILD    │    │
         │            │   • Build .app   │    │
         │            │   • Upload GitHub│    │
         │            └────────┬─────────┘    │
         │                     │               │
         │            ┌──────────────────┐    │
         │            │  WINDOWS BUILD   │    │
         │            │  • Build .exe    │    │
         │            │  • Upload GitHub │    │
         │            └────────┬─────────┘    │
         │                     │               │
         └─────────────────────┴───────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│                     DISTRIBUTION                                  │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  GitHub Actions Artifacts:                                       │
│  ├── release-apk (30 days)                                       │
│  ├── release-aab (30 days)                                       │
│  ├── release-ipa (30 days)                                       │
│  ├── release-macos (30 days)                                     │
│  └── release-windows (30 days)                                   │
│                                                                   │
│  Firebase App Distribution:                                      │
│  ├── Android App (permanent until deleted)                       │
│  └── iOS App (permanent until deleted)                           │
│                                                                   │
└───────────────────────────┬──────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│                        TESTERS                                    │
│                 (Receive email notifications)                     │
│                 Install and test the apps                         │
└──────────────────────────────────────────────────────────────────┘
```

## Environment Variables & Secrets

### GitHub Secrets (Required)

```
┌─────────────────────────────────────┐
│      GitHub Repository Secrets       │
├─────────────────────────────────────┤
│                                     │
│  • FIREBASE_TOKEN                   │
│    └─► Authenticates with Firebase │
│                                     │
│  • FIREBASE_APP_ID_ANDROID          │
│    └─► Identifies Android app      │
│                                     │
│  • FIREBASE_APP_ID_IOS              │
│    └─► Identifies iOS app          │
│                                     │
└─────────────────────────────────────┘
```

## Branch Strategy

```
develop branch:
  • Runs tests only
  • No builds
  • No deployments
  ↓
  Pull Request
  ↓
main branch:
  • Runs tests
  • Builds all platforms ✅
  • Deploys to Firebase ✅
  • Uploads artifacts ✅
```

## Timeline Example

```
Time    Action                              Status
────────────────────────────────────────────────────────────
00:00   Developer pushes to main           🚀 Started
00:01   Test job starts (Ubuntu)           🏃 Running
00:03   Tests complete                     ✅ Passed
00:03   Build jobs start (parallel)        🏃 Running
        ├── Android (Ubuntu)
        ├── iOS (macOS)
        ├── macOS (macOS)
        └── Windows (Windows)
00:08   Android build complete             ✅ Done
00:09   Android deployed to Firebase       🔥 Live
00:10   iOS build complete                 ✅ Done
00:11   iOS deployed to Firebase           🔥 Live
00:12   macOS build complete               ✅ Done
00:13   Windows build complete             ✅ Done
00:13   Testers receive notifications      📧 Sent
00:14   Pipeline complete                  ✨ Success
```

## Access Points

### For Developers:

```
GitHub Repository
  └── Actions Tab
      ├── View workflow runs
      ├── Download artifacts
      └── Check logs
```

### For Testers:

```
Email Notification
  └── Click "Download on Firebase"
      ├── Opens Firebase App Distribution
      ├── Install Android/iOS app
      └── Provide feedback
```

## Monitoring & Debugging

### Success Indicators:

- ✅ All jobs show green checkmarks
- ✅ Artifacts appear in GitHub Actions
- ✅ Apps appear in Firebase Console
- ✅ Testers receive email notifications

### Failure Points:

- ❌ Tests fail → Fix code and push again
- ❌ Build fails → Check logs for errors
- ❌ Firebase fails → Verify secrets are correct
- ❌ Upload fails → Check artifact paths

### Where to Look:

```
GitHub Actions Failed:
  → Go to Actions tab
  → Click on failed run
  → Expand failed step
  → Read error logs

Firebase Failed:
  → Check Firebase Console
  → View App Distribution logs
  → Verify App IDs match
  → Confirm tester group exists
```

## Summary

This CI/CD pipeline provides:

1. ✅ **Automated Testing** on every push
2. ✅ **Multi-platform Builds** on main branch
3. ✅ **Automated Distribution** via Firebase
4. ✅ **Artifact Storage** in GitHub
5. ✅ **Tester Notifications** via email
6. ✅ **Parallel Execution** for faster builds

Total pipeline time: ~15 minutes from push to tester notification

