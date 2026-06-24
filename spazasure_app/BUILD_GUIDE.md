# SpazaSure Release Build Guide

## Android APK (Ready!)
- **File**: `build/app/outputs/flutter-apk/app-release.apk` (68.4 MB)
- **Bundle**: `build/app/outputs/bundle/release/app-release.aab` (for Google Play Store)
- Also copied to: `C:\Users\Administrator\Desktop\SpazaSure-Release\`

### To install APK on phone:
1. Transfer `SpazaSure-v1.0.0.apk` to your Android phone
2. Open the file on the phone
3. Allow "Install from unknown sources" if prompted
4. Tap Install

### To publish to Google Play:
1. Go to https://play.google.com/console
2. Create new app "SpazaSure"
3. Upload `SpazaSure-v1.0.0.aab`
4. Fill in store listing, screenshots, etc.
5. Submit for review

---

## iOS Build (Requires Mac)

iOS apps CANNOT be built on Windows. You need a Mac with Xcode.

### Option 1: Build on a Mac
1. Clone the repo: `git clone https://github.com/moloi/Spaza-Project.git`
2. `cd spazasure_app`
3. `flutter pub get`
4. `cd ios && pod install && cd ..`
5. `flutter build ipa --release`
6. The IPA will be at `build/ios/ipa/spazasure_app.ipa`

### Option 2: Use Codemagic (Recommended - Free)
- Go to https://codemagic.io
- Connect your GitHub repo
- Select Flutter project
- It builds iOS on their Mac servers automatically
- Downloads the IPA for you

### iOS Setup Checklist:
- [x] Info.plist configured with permissions (camera, location, photos)
- [x] App name set to "SpazaSure"
- [x] Bundle ID: com.spazasure.spazasure_app
- [ ] Apple Developer Account ($99/year) needed for App Store
- [ ] Provisioning profile & certificates (auto-managed by Xcode)

---

## App Details
- **App Name**: SpazaSure
- **Version**: 1.0.0
- **Bundle ID**: com.spazasure.spazasure_app
- **Min Android**: SDK 21 (Android 5.0)
- **Min iOS**: 12.0
- **Backend**: http://167.233.69.205
