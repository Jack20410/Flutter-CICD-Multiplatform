# Firebase App Distribution Setup Guide

This guide will help you set up Firebase App Distribution with GitHub Actions and Fastlane for your Flutter note app.

## Prerequisites

- Firebase account
- Firebase CLI installed on your local machine
- Access to your GitHub repository settings

## Step 1: Firebase Project Setup

### 1.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select your existing project
3. Follow the setup wizard

### 1.2 Add Apps to Firebase

#### For Android:
1. In Firebase Console, click "Add app" → Android
2. Enter your Android package name (found in `android/app/build.gradle.kts`)
3. Download `google-services.json` (optional for App Distribution)
4. Copy the **Firebase App ID** (format: `1:123456789:android:abcdef...`)

#### For iOS:
1. In Firebase Console, click "Add app" → iOS
2. Enter your iOS bundle identifier (found in `ios/Runner.xcodeproj/project.pbxproj`)
3. Download `GoogleService-Info.plist` (optional for App Distribution)
4. Copy the **Firebase App ID** (format: `1:123456789:ios:abcdef...`)

### 1.3 Enable Firebase App Distribution

1. In Firebase Console, go to **Release & Monitor** → **App Distribution**
2. Click "Get started"
3. Create a tester group called **"testers"** (or use your preferred name)
4. Add testers' email addresses

## Step 2: Get Firebase CLI Token

### 2.1 Install Firebase CLI (if not installed)

```bash
npm install -g firebase-tools
```

### 2.2 Login and Get Token

```bash
# Login to Firebase
firebase login

# Get CI token
firebase login:ci
```

Copy the token that appears. This will be your `FIREBASE_TOKEN`.

## Step 3: Install Fastlane Dependencies

### 3.1 Install Bundler (if not installed)

```bash
gem install bundler
```

### 3.2 Install Fastlane Gems

```bash
# For Android
cd android
bundle install

# For iOS
cd ../ios
bundle install
```

## Step 4: Configure GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add the following secrets:

### Required Secrets:

1. **FIREBASE_TOKEN**
   - Value: The token from `firebase login:ci`

2. **FIREBASE_APP_ID_ANDROID**
   - Value: Your Android Firebase App ID (e.g., `1:123456789:android:abcdef...`)
   - Find it in Firebase Console → Project Settings → Your Apps → Android app

3. **FIREBASE_APP_ID_IOS**
   - Value: Your iOS Firebase App ID (e.g., `1:123456789:ios:abcdef...`)
   - Find it in Firebase Console → Project Settings → Your Apps → iOS app

## Step 5: Test Locally (Optional)

### Test Android Deployment:

```bash
cd android
export FIREBASE_TOKEN="your-firebase-token"
export FIREBASE_APP_ID="your-android-app-id"
bundle exec fastlane deploy_to_firebase
```

### Test iOS Deployment:

```bash
cd ios
export FIREBASE_TOKEN="your-firebase-token"
export FIREBASE_APP_ID_IOS="your-ios-app-id"
bundle exec fastlane deploy_to_firebase
```

## Step 6: Trigger GitHub Actions

1. Commit and push your changes to the `main` branch:

```bash
git add .
git commit -m "Add Firebase App Distribution"
git push origin main
```

2. Go to GitHub → **Actions** tab
3. Watch the workflow run
4. Check Firebase Console → App Distribution for your builds

## Step 7: Customize Release Notes (Optional)

### Edit Fastlane Files:

#### For Android (`android/fastlane/Fastfile`):

```ruby
firebase_app_distribution(
  app: ENV["FIREBASE_APP_ID"],
  firebase_cli_token: ENV["FIREBASE_TOKEN"],
  android_artifact_type: "AAB",
  android_artifact_path: "../build/app/outputs/bundle/release/app-release.aab",
  groups: "testers",  # Change to your tester group name
  release_notes: "New features and bug fixes"  # Customize this
)
```

#### For iOS (`ios/fastlane/Fastfile`):

```ruby
firebase_app_distribution(
  app: ENV["FIREBASE_APP_ID_IOS"],
  firebase_cli_token: ENV["FIREBASE_TOKEN"],
  ipa_path: "../build/ios/iphoneos/app-release.ipa",
  groups: "testers",  # Change to your tester group name
  release_notes: "New iOS features and improvements"  # Customize this
)
```

## Step 8: Invite Testers

1. Go to Firebase Console → App Distribution
2. Click on your app (Android or iOS)
3. Click "Invite testers"
4. Add email addresses or use tester groups
5. Testers will receive an email invitation

## Troubleshooting

### Common Issues:

#### 1. "App not found" error
- Verify your Firebase App ID is correct
- Make sure the app is registered in Firebase Console

#### 2. "Authentication error"
- Regenerate your Firebase token: `firebase login:ci`
- Update the `FIREBASE_TOKEN` secret in GitHub

#### 3. "No testers found"
- Create a tester group named "testers" in Firebase Console
- Or update the `groups` parameter in your Fastfile

#### 4. Build fails on GitHub Actions
- Check the logs in GitHub Actions
- Verify all secrets are set correctly
- Make sure Ruby and Bundler are properly set up

#### 5. iOS build not appearing
- Check if the IPA was created successfully
- Verify iOS Firebase App ID is correct
- Check Firebase Console for error messages

## What Happens After Setup

When you push to the `main` branch:

1. ✅ Tests run automatically
2. ✅ Android APK & AAB are built
3. ✅ iOS IPA is built
4. ✅ Apps are uploaded to Firebase App Distribution
5. ✅ Testers receive notifications via email
6. ✅ Artifacts are also saved to GitHub Actions (30 days)

## Advanced Configuration

### Dynamic Release Notes

You can use git commit messages as release notes:

```ruby
# In your Fastfile
release_notes = `git log -1 --pretty=format:"%s"`

firebase_app_distribution(
  # ... other parameters
  release_notes: release_notes
)
```

### Multiple Tester Groups

```ruby
firebase_app_distribution(
  # ... other parameters
  groups: "testers,beta-testers,developers"
)
```

### Deploy to Specific Testers

```ruby
firebase_app_distribution(
  # ... other parameters
  testers: "tester1@example.com,tester2@example.com"
)
```

## Resources

- [Firebase App Distribution Documentation](https://firebase.google.com/docs/app-distribution)
- [Fastlane Firebase Plugin](https://firebase.google.com/docs/app-distribution/android/distribute-fastlane)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## Need Help?

If you encounter issues:
1. Check Firebase Console logs
2. Review GitHub Actions logs
3. Verify all environment variables and secrets
4. Check Fastlane output for detailed error messages

