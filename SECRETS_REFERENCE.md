# GitHub Secrets Quick Reference

This is a quick reference for all the GitHub secrets you need to set up.

## How to Add Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret below

---

## Required Secrets for Firebase App Distribution

### 1. FIREBASE_TOKEN

**How to get it:**
```bash
firebase login:ci
```

**What it looks like:**
```
1//0abc-defGHIjklMNOpqrSTUVwxyz...
```

**Used for:** Authenticating with Firebase from CI/CD

---

### 2. FIREBASE_APP_ID_ANDROID

**How to get it:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click ⚙️ (Settings) → Project Settings
4. Scroll down to "Your apps"
5. Click on your Android app
6. Copy the **App ID**

**What it looks like:**
```
1:123456789012:android:abc123def456
```

**Used for:** Identifying your Android app in Firebase

---

### 3. FIREBASE_APP_ID_IOS

**How to get it:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click ⚙️ (Settings) → Project Settings
4. Scroll down to "Your apps"
5. Click on your iOS app
6. Copy the **App ID**

**What it looks like:**
```
1:123456789012:ios:abc123def456
```

**Used for:** Identifying your iOS app in Firebase

---

## Optional Secrets (for Code Signing)

### For iOS Code Signing:

- `IOS_CERTIFICATE_P12` - Base64 encoded .p12 certificate
- `IOS_CERTIFICATE_PASSWORD` - Certificate password
- `IOS_PROVISIONING_PROFILE` - Base64 encoded provisioning profile

### For macOS Code Signing:

- `MACOS_CERTIFICATE_P12` - Base64 encoded certificate
- `MACOS_CERTIFICATE_PASSWORD` - Certificate password
- `MACOS_SIGNING_IDENTITY` - Certificate identity
- `APPLE_ID` - Your Apple ID email
- `APPLE_APP_PASSWORD` - App-specific password
- `APPLE_TEAM_ID` - Your team ID

---

## Verification Checklist

Use this checklist to verify your setup:

- [ ] FIREBASE_TOKEN is set
- [ ] FIREBASE_APP_ID_ANDROID is set
- [ ] FIREBASE_APP_ID_IOS is set
- [ ] Android app is registered in Firebase Console
- [ ] iOS app is registered in Firebase Console
- [ ] Tester group "testers" exists in Firebase App Distribution
- [ ] Testers are added to the group
- [ ] Fastlane dependencies are installed locally (`bundle install`)
- [ ] Workflow file is updated and committed

---

## Testing Your Setup

### Test if secrets are working:

1. Push to `main` branch
2. Go to **Actions** tab on GitHub
3. Watch the workflow run
4. If it fails, check the logs for which secret is missing/incorrect

### Test locally first:

```bash
# Test Android
cd android
export FIREBASE_TOKEN="your-token"
export FIREBASE_APP_ID="your-android-app-id"
bundle exec fastlane deploy_to_firebase

# Test iOS
cd ios
export FIREBASE_TOKEN="your-token"
export FIREBASE_APP_ID_IOS="your-ios-app-id"
bundle exec fastlane deploy_to_firebase
```

---

## Quick Setup Commands

```bash
# 1. Get Firebase token
firebase login:ci

# 2. Install dependencies
cd android && bundle install
cd ../ios && bundle install

# 3. Add secrets to GitHub (manually through web interface)
# - FIREBASE_TOKEN
# - FIREBASE_APP_ID_ANDROID
# - FIREBASE_APP_ID_IOS

# 4. Push to main
git add .
git commit -m "Setup Firebase App Distribution"
git push origin main
```

---

## Common Mistakes

❌ **Wrong:** Using Firebase Project ID instead of Firebase App ID  
✅ **Right:** Use the App ID from "Your apps" section (starts with `1:`)

❌ **Wrong:** Forgetting to set secrets in GitHub  
✅ **Right:** All 3 required secrets must be set

❌ **Wrong:** Using expired Firebase token  
✅ **Right:** Generate fresh token with `firebase login:ci`

❌ **Wrong:** Not creating "testers" group in Firebase  
✅ **Right:** Create tester group before deployment

---

## Need to Update Secrets?

1. Go to GitHub repository → Settings → Secrets and variables → Actions
2. Click on the secret name
3. Click "Update secret"
4. Paste new value
5. Click "Update secret"

Secrets are encrypted and can't be viewed after creation, only updated or deleted.

