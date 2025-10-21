# Firebase App Distribution Deployment Checklist

Use this checklist to ensure everything is set up correctly for automated deployment.

## ✅ Pre-Setup Checklist

- [ ] Firebase account created
- [ ] Firebase project created
- [ ] Node.js installed (for Firebase CLI)
- [ ] Ruby and Bundler installed
- [ ] Git repository connected to GitHub

---

## 🔧 Firebase Configuration

### Firebase Console Setup

- [ ] **Created Firebase Project**
  - Project name: _________________
  - Project ID: ___________________

- [ ] **Registered Android App**
  - Package name: _________________
  - Firebase App ID copied: [ ]
  - Format: `1:123456789:android:abc123...`

- [ ] **Registered iOS App**
  - Bundle ID: ____________________
  - Firebase App ID copied: [ ]
  - Format: `1:123456789:ios:abc123...`

- [ ] **App Distribution Enabled**
  - Navigated to: Release & Monitor → App Distribution
  - Clicked "Get started"

- [ ] **Tester Group Created**
  - Group name: `testers` (or custom: _________)
  - Testers added: [ ]
  - Number of testers: ___________

### Firebase CLI

- [ ] **Firebase CLI Installed**
  ```bash
  npm install -g firebase-tools
  ```

- [ ] **Logged in to Firebase**
  ```bash
  firebase login
  ```

- [ ] **Generated CI Token**
  ```bash
  firebase login:ci
  ```
  - Token copied: [ ]
  - Token stored securely: [ ]

---

## 📦 Local Setup

### Fastlane Dependencies

- [ ] **Android Fastlane Setup**
  ```bash
  cd android
  bundle install
  ```

- [ ] **iOS Fastlane Setup**
  ```bash
  cd ios
  bundle install
  ```

### Test Locally (Optional but Recommended)

- [ ] **Test Android Deployment**
  ```bash
  cd android
  export FIREBASE_TOKEN="your-token"
  export FIREBASE_APP_ID="your-android-app-id"
  bundle exec fastlane deploy_to_firebase
  ```

- [ ] **Test iOS Deployment**
  ```bash
  cd ios
  export FIREBASE_TOKEN="your-token"
  export FIREBASE_APP_ID_IOS="your-ios-app-id"
  bundle exec fastlane deploy_to_firebase
  ```

---

## 🔐 GitHub Secrets Configuration

Go to: GitHub Repository → Settings → Secrets and variables → Actions

### Required Secrets

- [ ] **FIREBASE_TOKEN**
  - Value: `___________________________________`
  - Added to GitHub: [ ]
  - Verified: [ ]

- [ ] **FIREBASE_APP_ID_ANDROID**
  - Value: `___________________________________`
  - Added to GitHub: [ ]
  - Verified: [ ]

- [ ] **FIREBASE_APP_ID_IOS**
  - Value: `___________________________________`
  - Added to GitHub: [ ]
  - Verified: [ ]

### Verification

- [ ] All 3 secrets visible in GitHub Secrets page
- [ ] Secret names match exactly (case-sensitive)
- [ ] No extra spaces in secret values

---

## 🚀 Deployment Setup

### Files Created/Updated

- [ ] `.github/workflows/ci-cd.yml` updated with:
  - Android deployment step
  - iOS deployment step
  - Ruby setup for both platforms

- [ ] `ios/fastlane/Fastfile` created
- [ ] `ios/fastlane/Pluginfile` created
- [ ] `ios/Gemfile` created
- [ ] `ios/fastlane/Appfile` created

- [ ] `android/fastlane/Fastfile` already exists
- [ ] `android/fastlane/Pluginfile` already exists

### Documentation

- [ ] `FIREBASE_SETUP_GUIDE.md` created
- [ ] `SECRETS_REFERENCE.md` created
- [ ] `CI_CD_WORKFLOW.md` created
- [ ] `DEPLOYMENT_CHECKLIST.md` created (this file)
- [ ] `README.md` updated with deployment info

---

## 🧪 Testing the Pipeline

### Initial Deployment

- [ ] **Commit Changes**
  ```bash
  git add .
  git commit -m "Setup Firebase App Distribution with CI/CD"
  ```

- [ ] **Push to Main Branch**
  ```bash
  git push origin main
  ```

- [ ] **Monitor GitHub Actions**
  - Go to: Repository → Actions tab
  - Watch workflow run in real-time
  - Check for any errors

### Verify Builds

- [ ] **Test Job Completed**
  - Formatting passed: [ ]
  - Analysis passed: [ ]
  - Tests passed: [ ]

- [ ] **Android Build Completed**
  - APK built: [ ]
  - AAB built: [ ]
  - Uploaded to GitHub: [ ]
  - Deployed to Firebase: [ ]

- [ ] **iOS Build Completed**
  - IPA built: [ ]
  - Uploaded to GitHub: [ ]
  - Deployed to Firebase: [ ]

- [ ] **macOS Build Completed**
  - .app built: [ ]
  - Uploaded to GitHub: [ ]

- [ ] **Windows Build Completed**
  - .exe built: [ ]
  - Uploaded to GitHub: [ ]

### Verify Firebase Distribution

- [ ] **Check Firebase Console**
  - Go to: Firebase Console → App Distribution
  - Android app appears: [ ]
  - iOS app appears: [ ]
  - Both show recent builds: [ ]

- [ ] **Check Tester Notifications**
  - Testers received emails: [ ]
  - Email contains download link: [ ]
  - Link works correctly: [ ]

---

## 📱 Tester Experience

### Tester Setup

- [ ] **Testers Invited**
  - Invitation emails sent: [ ]
  - Testers accepted invitations: [ ]

- [ ] **Testers Can Access Apps**
  - Android app downloadable: [ ]
  - iOS app downloadable: [ ]
  - Apps install successfully: [ ]

### Testing Feedback Loop

- [ ] Feedback mechanism established
- [ ] Bug reporting process defined
- [ ] Communication channel set up (email, Slack, etc.)

---

## 🔍 Troubleshooting

### If Pipeline Fails

- [ ] Check GitHub Actions logs for errors
- [ ] Verify all secrets are set correctly
- [ ] Confirm Firebase App IDs are correct
- [ ] Ensure tester group "testers" exists
- [ ] Check Firebase Console for error messages

### Common Issues Resolved

- [ ] ✅ No "App not found" errors
- [ ] ✅ No authentication errors
- [ ] ✅ No tester group errors
- [ ] ✅ Artifacts upload successfully
- [ ] ✅ Firebase deployment succeeds

---

## 📊 Success Criteria

### All Green Checkmarks

- [ ] GitHub Actions workflow completes successfully
- [ ] All build jobs complete (Android, iOS, macOS, Windows)
- [ ] All artifacts uploaded to GitHub
- [ ] Android & iOS apps deployed to Firebase
- [ ] Testers receive notification emails
- [ ] Apps are installable and functional

---

## 🎯 Next Steps

### After Successful Setup

- [ ] **Monitor First Few Deployments**
  - Check logs regularly
  - Gather tester feedback
  - Fix any issues quickly

- [ ] **Optimize Workflow** (Optional)
  - Add dynamic release notes from commits
  - Set up multiple tester groups
  - Add code signing for production releases

- [ ] **Document Process**
  - Create team documentation
  - Train team members
  - Establish deployment schedule

### Production Readiness

- [ ] Add code signing for iOS (if needed)
- [ ] Add notarization for macOS (if needed)
- [ ] Set up Play Store deployment (optional)
- [ ] Set up App Store deployment (optional)
- [ ] Configure release channels (alpha, beta, production)

---

## 📝 Notes

Use this space for any specific notes about your setup:

```
_______________________________________________________________

_______________________________________________________________

_______________________________________________________________

_______________________________________________________________

_______________________________________________________________
```

---

## 🎉 Completion

**Setup Completed On:** _____________________

**First Successful Deploy:** _____________________

**Team Members Trained:** _____________________

**Status:** 
- [ ] In Progress
- [ ] Completed
- [ ] Production Ready

---

## 📚 Resources

Quick links for reference:

- Firebase Console: https://console.firebase.google.com/
- GitHub Actions: [Your Repo]/actions
- Setup Guide: FIREBASE_SETUP_GUIDE.md
- Secrets Reference: SECRETS_REFERENCE.md
- Workflow Diagram: CI_CD_WORKFLOW.md
- README: README.md

---

**Last Updated:** [Date]
**Maintained By:** [Your Name/Team]

