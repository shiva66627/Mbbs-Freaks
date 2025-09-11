# Google Drive API Setup Instructions

## Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Create Project" or select existing project
3. Name your project (e.g., "MBBS Study App")
4. Click "Create"

## Step 2: Enable Google Drive API

1. In Google Cloud Console, go to **APIs & Services > Library**
2. Search for "Google Drive API"
3. Click on "Google Drive API" 
4. Click **"Enable"**

## Step 3: Configure OAuth Consent Screen

1. Go to **APIs & Services > OAuth consent screen**
2. Choose **"External"** user type
3. Fill in required information:
   - **App name**: Your app name (e.g., "MBBS Study App")
   - **User support email**: Your email
   - **Developer contact information**: Your email
4. Click **"Save and Continue"**
5. **Scopes**: Click "Add or Remove Scopes"
   - Add: `https://www.googleapis.com/auth/drive.readonly`
   - Click "Update"
6. **Test users**: Add your email address and any other test users
7. Click **"Save and Continue"**

## Step 4: Create OAuth Credentials

1. Go to **APIs & Services > Credentials**
2. Click **"+ CREATE CREDENTIALS"**
3. Select **"OAuth client ID"**
4. Choose **"Android"** application type
5. **Name**: Give it a name (e.g., "Android Client")
6. **Package name**: `com.example.demo2` (from your app)
7. **SHA-1 certificate fingerprint**: Get this by running:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   Copy the SHA-1 fingerprint
8. Click **"Create"**

## Step 5: Download and Add Configuration

1. Download the `google-services.json` file
2. Place it in `android/app/` folder of your Flutter project
3. Make sure it's at the same level as your `build.gradle` file

## Step 6: Add Test Users (For Development)

1. In OAuth consent screen, go to **"Test users"**
2. Add email addresses of people who will test the app
3. Only these users can sign in during development

## Step 7: Publish App (When Ready)

When ready for production:
1. Go to OAuth consent screen
2. Click **"Publish App"**
3. This removes the "unverified" warning for all users

## Alternative: Use Your Own Google Account

For immediate testing, you can:
1. Make sure you're signed in to Google with the same account used to create the project
2. Or add your testing email to the "Test users" list

## Web Client ID (If Needed)

If you need web client ID for Google Sign-In:
1. Create another OAuth client ID
2. Choose **"Web application"**
3. Add authorized redirect URIs if needed
