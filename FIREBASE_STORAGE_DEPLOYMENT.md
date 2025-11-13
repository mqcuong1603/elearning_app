# Firebase Storage Rules Deployment Instructions

## Problem Solved

You were experiencing a `[firebase_storage/object-not-found]` error when submitting assignments. This error was caused by missing Firebase Storage security rules that blocked all file uploads.

## Changes Made

1. **Created `storage.rules`**: Added comprehensive Firebase Storage security rules that allow authenticated users to upload files.

2. **Updated `firebase.json`**: Added storage rules configuration.

3. **Improved `storage_service.dart`**: Enhanced error handling and added proper metadata to uploads.

## Required Action: Deploy Storage Rules

You **MUST** deploy the new storage rules to Firebase for uploads to work. Follow these steps:

### Step 1: Install Firebase CLI (if not already installed)

```bash
npm install -g firebase-tools
```

### Step 2: Login to Firebase

```bash
firebase login
```

This will open a browser window for you to authenticate with your Google account that has access to the Firebase project.

### Step 3: Deploy Storage Rules

Navigate to your project directory and run:

```bash
cd /path/to/elearning_app
firebase deploy --only storage --project elearning-management-b4314
```

Or if you've already set the active project:

```bash
firebase use elearning-management-b4314
firebase deploy --only storage
```

### Step 4: Verify Deployment

After deployment, you should see:

```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/elearning-management-b4314/overview
```

## Alternative: Deploy via Firebase Console

If you prefer to deploy manually through the web console:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `elearning-management-b4314`
3. Navigate to **Storage** in the left sidebar
4. Click on the **Rules** tab
5. Copy the contents of `storage.rules` file
6. Paste them into the editor
7. Click **Publish**

## Testing

After deploying the storage rules, test the assignment submission again:

1. Log in as a student
2. Navigate to an assignment
3. Select a file to submit
4. Click Submit

The upload should now work without the `object-not-found` error.

## Security Notes

The storage rules configured allow:
- **Read access**: Any authenticated user can read files
- **Write access**: Any authenticated user can upload files to their designated paths
- **File size limit**: Maximum 100MB per file
- **Allowed file types**: Documents (PDF, DOC, DOCX), images, videos, archives (ZIP, RAR), and text files

## Troubleshooting

If you still experience issues after deployment:

1. **Check authentication**: Ensure the user is properly logged in
2. **Verify storage bucket**: Confirm `elearning-management-b4314.firebasestorage.app` is accessible
3. **Check file format**: Ensure the file type is allowed in the assignment settings
4. **Review file size**: Ensure the file doesn't exceed the maximum allowed size
5. **Check logs**: Look at the Flutter console for detailed error messages

## Support

If you continue to experience issues, check:
- Firebase Console logs
- Flutter debug console output
- Network connectivity
- Firebase project billing status (ensure the project is on a paid plan if needed)
