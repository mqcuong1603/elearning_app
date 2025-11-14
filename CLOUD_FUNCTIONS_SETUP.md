# Firebase Cloud Functions Setup Guide

This guide will help you set up Firebase Cloud Functions to send email notifications when notifications are created in Firestore.

## 🎯 Overview

The Cloud Function automatically triggers when a new notification is created in Firestore and sends an email to the user using Nodemailer with Gmail.

## 📋 Prerequisites

1. **Firebase CLI** installed globally
2. **Node.js 18** or higher
3. **Gmail account** with 2-Factor Authentication enabled
4. **Billing enabled** on your Firebase project (Cloud Functions requires Blaze plan)

## 🚀 Step-by-Step Setup

### Step 1: Install Firebase CLI (if not already installed)

```bash
npm install -g firebase-tools
```

### Step 2: Login to Firebase

```bash
firebase login
```

### Step 3: Install Dependencies

Navigate to the functions directory and install dependencies:

```bash
cd functions
npm install
```

### Step 4: Configure Gmail for Sending Emails

#### Create a Gmail App Password

1. Go to your Google Account: https://myaccount.google.com/security
2. Make sure **2-Step Verification** is enabled
3. Search for "App passwords" or go to: https://myaccount.google.com/apppasswords
4. Select "Mail" as the app and "Other" as the device
5. Enter "Firebase Cloud Functions" as the device name
6. Click **Generate**
7. Copy the 16-character password (it will look like: `abcd efgh ijkl mnop`)

#### Set Environment Variables in Firebase

Set your Gmail credentials as environment variables:

```bash
# From the project root directory
firebase functions:config:set gmail.email="your-email@gmail.com"
firebase functions:config:set gmail.password="your-16-char-app-password"
```

**Important:** Remove the spaces from the app password when setting it!

### Step 5: Build the Functions

```bash
# From the functions directory
npm run build
```

### Step 6: Deploy to Firebase

Deploy the Cloud Functions:

```bash
# From the project root directory
firebase deploy --only functions
```

Or deploy just the notification email function:

```bash
firebase deploy --only functions:sendNotificationEmail
```

## 🧪 Testing

### Test Locally with Firebase Emulator (Optional)

1. Download the config to test locally:

```bash
firebase functions:config:get > functions/.runtimeconfig.json
```

2. Start the emulator:

```bash
cd functions
npm run serve
```

3. Create a test notification in your app and check if the email is sent

### Test in Production

1. Deploy the function (as shown above)
2. Create a notification in your app
3. Check the user's email inbox
4. Check Firebase Console logs for any errors:

```bash
firebase functions:log
```

## 📊 Monitoring

### View Logs

```bash
firebase functions:log
```

### View Logs for Specific Function

```bash
firebase functions:log --only sendNotificationEmail
```

### Check Function Status

Go to Firebase Console → Functions to see:
- Function execution status
- Error rates
- Execution time
- Number of invocations

## 🔧 Troubleshooting

### Email not sending?

1. **Check if environment variables are set:**
   ```bash
   firebase functions:config:get
   ```

2. **Check function logs:**
   ```bash
   firebase functions:log
   ```

3. **Common issues:**
   - App password not set correctly (make sure to remove spaces)
   - 2-Factor Authentication not enabled on Gmail
   - Gmail blocking "less secure apps" (use app password instead)
   - User doesn't have email in Firestore
   - Firebase project not on Blaze (paid) plan

### Function not triggering?

1. Check that notifications are being created in Firestore
2. Verify the collection name is "notifications"
3. Check function deployment status in Firebase Console

### "Configuration gmail.email is not available" error

This means the environment variables weren't set. Run:
```bash
firebase functions:config:set gmail.email="your-email@gmail.com"
firebase functions:config:set gmail.password="your-app-password"
```

Then redeploy:
```bash
firebase deploy --only functions
```

## 💰 Cost Considerations

Firebase Cloud Functions pricing (Blaze plan):
- **Free tier:** 2 million invocations/month
- **After free tier:** $0.40 per million invocations
- **Networking:** First 5 GB/month free

For a typical e-learning app, costs should be minimal unless you have thousands of notifications per day.

## 🎨 Customizing the Email

The email template is in `functions/src/index.ts` in the `generateEmailHTML` function. You can customize:
- Email styling (CSS)
- Email content
- Email subject line
- Sender name

## 🔐 Security Best Practices

1. **Never commit `.runtimeconfig.json`** - it's in .gitignore
2. **Use app passwords** instead of your actual Gmail password
3. **Limit email sending** to prevent spam (consider rate limiting)
4. **Validate user emails** before sending

## 📱 Next Steps

After deployment, the function will automatically:
1. ✅ Trigger when a notification is created in Firestore
2. ✅ Fetch the user's email from the users collection
3. ✅ Send a formatted HTML email
4. ✅ Log the result (success or error)

This works across **all platforms** (web, mobile, desktop) since it's serverless!

## 🆘 Need Help?

- Firebase Functions docs: https://firebase.google.com/docs/functions
- Nodemailer docs: https://nodemailer.com/
- Firebase support: https://firebase.google.com/support

---

**Created:** November 2024
**Last Updated:** November 2024
